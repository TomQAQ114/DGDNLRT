function x0 = TV_denoising(y0,lambda,iter)

if nargin<3
    iter = 100;
end
z= zeros(max(size(y0)-1,1));  % the differential
%z= zeros(max(size(y0)-1,1));  % the differential
alpha = 5;%调整梯度更新的步长
for it = 1:iter
    if(size(y0,2)==1)  % 1D vectory一维向量
    x0 = y0 - dvt(z);
    z = clip(z + 1/alpha*dv(x0), lambda/2);
    elseif(size(y0,2)>1 && (size(y0,3)==1))  % 2D image2D图像
        if(it ==1)
            zh = zeros(size(y0,1), size(y0,2)-1);
            zv = zeros(size(y0,1)-1, size(y0,2));
        end
    x0h = y0 - dht(zh);% 使用dht_3d函数计算水平方向xoz的梯度，然后从原始图像中减去这些梯度，得到去噪后的图像x0h
    x0v = y0 - dvt(zv);% 使用dvt_3d函数计算垂直方向yoz的梯度，然后从原始图像中减去这些梯度，得到去噪后的图像x0v     
    x0 = (x0h + x0v)./2;
    zh = clip(zh + 1/alpha*dh(x0), lambda/2);%1000*999*32
    zv = clip(zv + 1/alpha*dv(x0), lambda/2);%999*1000*32
    elseif(size(y0,3)>1 && (size(y0,4)==1))  % 3D video or hyperspectral images, but TV is done by each 2D frame3D视频或高光谱图像
        if(it ==1)
            zh = zeros(size(y0,1), size(y0,2)-1, size(y0,3)); % 初始化水平梯度
            zv = zeros(size(y0,1)-1, size(y0,2), size(y0,3)); % 初始化垂直梯度
        end
    x0h = y0 - dht_3d(zh);
    x0v = y0 - dvt_3d(zv);
    x0 = (x0h + x0v)./2;
    zh = clip(zh + 1/alpha*dh(x0), lambda/2);
    zv = clip(zv + 1/alpha*dv(x0), lambda/2);
    elseif(size(y0,4)>1 && (size(y0,5)==1))  % 4D hyperspectral-video, but TV is done by each 2D frame
        if(it ==1)
            zh = zeros(size(y0,1), size(y0,2)-1, size(y0,3) , size(y0,4));
            zv = zeros(size(y0,1)-1, size(y0,2), size(y0,3) , size(y0,4));
        end
    x0h = y0 - dht_4d(zh);
    x0v = y0 - dvt_4d(zv);
    x0 = (x0h + x0v)./2;
    zh = clip(zh + 1/alpha*dh(x0), lambda/2);
    zv = clip(zv + 1/alpha*dv(x0), lambda/2);
    end
end





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
        
    
    
    
function y =clip(x, lambda)
    y = sign(x).*(min(abs(x),lambda));