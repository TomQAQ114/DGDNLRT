function x0 = TV_denoising_weighted(y0, lambda, W, iter)
% WEIGHTED_TV_DENOISING 加权全变分去噪函数
% 在传统TV去噪基础上添加权重矩阵支持
%
% 输入参数:
%   y0 - 带噪声的输入图像
%   lambda - 正则化参数
%   W - 权重矩阵，与y0同尺寸，值越大表示该位置越不可靠
%   iter - 迭代次数

if nargin < 4
    iter = 100;
end
it =1;
alpha = 5; % 调整梯度更新的步长

% 根据输入维度处理权重矩阵
if(size(y0,2)==1)  % 1D向量
    % 1D情况下直接使用权重
    W_used = W;
    z = zeros(max(size(y0)-1,1));  % 初始化对偶变量
    
elseif(size(y0,2)>1 && (size(y0,3)==1))  % 2D图像
    % 为水平和垂直方向准备权重矩阵
    if(it ==1)
        zh = zeros(size(y0,1), size(y0,2)-1);
        zv = zeros(size(y0,1)-1, size(y0,2));
        
        % 计算水平方向权重 (相邻像素平均)
        W_h = (W(:, 1:end-1) + W(:, 2:end)) / 2;
        % 计算垂直方向权重 (相邻像素平均)
        W_v = (W(1:end-1, :) + W(2:end, :)) / 2;
    end
    
elseif(size(y0,3)>1 && (size(y0,4)==1))  % 3D视频或高光谱图像
    if(it ==1)
        zh = zeros(size(y0,1), size(y0,2)-1, size(y0,3));
        zv = zeros(size(y0,1)-1, size(y0,2), size(y0,3));
        
        % 为3D数据的每个通道准备权重
        W_h = W(:, 1:end-1, :); %+ W(:, 2:end, :)) / 2;
        W_v = W(1:end-1, :, :); %+ W(2:end, :, :)) / 2;
    end
    
elseif(size(y0,4)>1 && (size(y0,5)==1))  % 4D高光谱视频
    if(it ==1)
        zh = zeros(size(y0,1), size(y0,2)-1, size(y0,3), size(y0,4));
        zv = zeros(size(y0,1)-1, size(y0,2), size(y0,3), size(y0,4));
        
        % 为4D数据准备权重
        W_h = (W(:, 1:end-1, :, :) + W(:, 2:end, :, :)) / 2;
        W_v = (W(1:end-1, :, :, :) + W(2:end, :, :, :)) / 2;
    end
end

% 主迭代循环
for it = 1:iter
    if(size(y0,2)==1)  % 1D向量
        x0 = y0 - dvt(z);
        % 使用加权clip函数
        z = weighted_clip(z + 1/alpha*dv(x0), lambda/2, W_used);
        
    elseif(size(y0,2)>1 && (size(y0,3)==1))  % 2D图像
        x0h = y0 - dht(zh);
        x0v = y0 - dvt(zv);
        x0 = (x0h + x0v)./2;
        
        % 使用加权clip函数，传入方向特定的权重
        zh = weighted_clip(zh + 1/alpha*dh(x0), lambda/2, W_h);
        zv = weighted_clip(zv + 1/alpha*dv(x0), lambda/2, W_v);
        
    elseif(size(y0,3)>1 && (size(y0,4)==1))  % 3D视频或高光谱图像
        x0h = y0 - dht_3d(zh);
        x0v = y0 - dvt_3d(zv);
        x0 = (x0h + x0v)./2;
        
        % 使用加权clip函数
        zh = weighted_clip(zh + 1/alpha*dh(x0), lambda, W_h);
        zv = weighted_clip(zv + 1/alpha*dv(x0), lambda, W_v);
        
    elseif(size(y0,4)>1 && (size(y0,5)==1))  % 4D高光谱视频
        x0h = y0 - dht_4d(zh);
        x0v = y0 - dvt_4d(zv);
        x0 = (x0h + x0v)./2;
        
        % 使用加权clip函数
        zh = weighted_clip(zh + 1/alpha*dh(x0), lambda/2, W_h);
        zv = weighted_clip(zv + 1/alpha*dv(x0), lambda/2, W_v);
    end
end

% 辅助函数保持不变
function y = dv(x)
    y = diff(x);

function y = dh(x)
    y = diff(x,1,2);
    
function y = dvt(x)
    y = [-x(1,:); -diff(x) ; x(end,:)];

function y = dht(x)
    y = [-x(:,1) -diff(x,1,2) x(:,end)];
    
function y = dvt_3d(x)
    y = cat(1, -x(1,:,:), -diff(x) , x(end,:,:));

function y = dht_3d(x)
    y = cat(2, -x(:,1,:), -diff(x,1,2), x(:,end,:));

function y = dvt_4d(x)
    y = cat(1, -x(1,:,:,:), -diff(x) , x(end,:,:,:));

function y = dht_4d(x)
    y = cat(2, -x(:,1,:,:), -diff(x,1,2), x(:,end,:,:));

% 新的加权clip函数
function y = weighted_clip(x, lambda, weight_matrix)
    % 加权clip函数：使用位置相关的阈值
    % 输入:
    %   x - 输入值
    %   lambda - 基础阈值参数
    %   weight_matrix - 权重矩阵，与x同尺寸
    
    % 计算位置相关的阈值
    threshold = lambda * weight_matrix;
    
    % 应用加权clip操作
    y = sign(x) .* min(abs(x), threshold);
