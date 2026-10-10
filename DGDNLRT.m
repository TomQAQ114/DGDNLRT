clc;clear;close all;

fullpath = mfilename('fullpath');% 当前文件的完整路径
[curpath, ~] = fileparts(fullpath);
cd(curpath);

%% tools loading
%dname = {'scene01'};
%for lamada=0.5:0.1:1.5
for k=1.0
% dname = {'Face'};%'Cloth','Toy','Egyptian','Clay'
site = {[512 384]};%,[100 100],[125,125],[90 90],[175,175]
dname = {'scene02','scene03','scene04','scene05','scene09'};
% dname = {'S6','S7','S8','S9','S10'};%,'S7','S8','S9','S10'
% save_path = "./out/real";
for i = 1:length(dname)
for s = 1:length(site)
addpath(genpath('./tools'));% genpath() 生成路径名称，包含指定路径及其多级子文件夹， addpath() 添加到搜索路径
addpath(genpath('./utils'));
addpath(genpath('./funs'));
addpath(genpath('./datasets'));
%% data loading
fprintf("loading data...\n");
dataload_path = "./datasets/simdata/benchmark";%/Toy.mat";
% dataload_path = "./datasets/CAVE";%/Toy.mat";
% dataload_path = "./datasets/ICVL";%/Toy.mat";
% % dataload_path = "E:\dataset\Cassi_dataset\TSA_simu_data\Truth\scene09" + ...
% %     ".mat";
maskload_path = "./datasets";%/mask_for_512.mat";
% maskload_path = "E:\dataset\Cassi_dataset\TSA_simu_data\mask.mat";

fprintf("Data loading...\n");

dataname = dname{i}; % [default] data name
L = site{s};
%measname = 'meas_scene01'; % [default] meas name
maskname = 'mask_for_512';
datapath = sprintf('%s/%s.mat',dataload_path,dataname);
% measpath = sprintf('%s/%s.mat',measdir,measname);
maskpath = sprintf('%s/%s.mat',maskload_path,maskname);
% load(dataload_path, 'orig');
if exist(datapath,'file')
    load(datapath,'img');% img
%     load(measpath,'meas');% meas
    load(maskpath,'mask');% mask
else
    error('File %s does not exist, please check dataset directory!',datapath);
end
% 
orig = double(img);
% load(dataload_path,'img');
% orig = double(img);clear img;
% load(maskload_path, 'mask');   % 读入函数orig, mask
for j=7
mask1 = save_gray_image_as_mat('/data/HZP/NLRT-main/NLRT-main/real_masks/mask_1.tiff',256,'center');
[mu1, mu2, sigma1, sigma2, mask1] = fit_GMM_mask(mask1);
mask = double(mask1);
[nrows, ncols, dims] = size(orig);
% [W, gmm_param] = mask2weight(mask1);
% W = repmat(W, [1, 1, dims]);
% W = shift(W,2);
W = compute_DGD_weight(mask1, mu1, sigma1, mu2, sigma2,k);
% W = [];
real_test = false;
if real_test
    load("/data/HZP/NLRT-main/NLRT-main/datasets/real/scene3.mat");
    meas = double(meas_real);clear meas_real;
    %mask = mask_clip;clear mask_clip;
end
mask = repmat(mask,1,1,dims); % 重复数据副本
% for j = 3.5e-3:1e-4:4.5e-3
%% 参数设置
step = 2;   % 色散步长
rho = 5e-6;
beta = 1e-3;
rank = 9;
gamma = 1e-3;
omega = 1e-5;   

winsize = 10;   % clustering
overlap = 5;

niters = 300;   % NLRT算法

%% coding and compressing

P = @(x) shift(x, step); % 色散操作
PT = @(x) shift_back(x, step); % 逆转操作

shifted_orig = P(orig);
shifted_mask = P(mask);


A = @(x) (sum(x.*shifted_mask, 3));      
AT = @(x) (bsxfun(@times, x, shifted_mask));  

[rows, cols, dims] = size(mask); 
[srows, scols, ~] = size(shifted_mask); 

if ~real_test
    meas = A(P(orig));
end



%% NLRT
fprintf("Start...\n");
if isempty(gcp('nocreate')) % enable parallel gcp() 获取当前parallel pool parfor
    p = parpool(12);
end

mytimestart = tic;

%% V.A. Measurement Image Restoration
fprintf("Step 1. Measurement image restorating...\n");

step1_time = tic;

S = zeros(srows,scols,dims);    % initial
T = zeros(rows,cols,dims);
E = S;

initial_image = ADMM_for_Smooth(meas,omega,rho,A,AT,P,PT,shifted_mask,W,...
                'initializer', {S,T,E},...
                'ADMM_iter',   10,...
                'TV_iter',     10);

% initial_image = mean(orig,3);
step1_time = toc(step1_time);
fprintf("step1_time:%f s\n", step1_time);

%% V.B. Nonlocal HSI Blocks Clustering
fprintf("Step 2.  Nonlocal HSI blocks clustering...\n");

step2_time = tic;

[mn_cell, bparams] = Clustering(initial_image, rows, cols,...
                'winsize',     10,...
                'overlap',     5,...
                'searchsz',    [7,7]);

step2_time = toc(step2_time);
fprintf("step2_time:%f s\n", step2_time);

%% V.C. Optimization Procedure
fprintf("Step 3. NLRT iter...\n");

step3_time = tic;

Y = meas;   % initial
X = zeros(rows,cols,dims);
V = zeros(srows,scols,dims);
M = zeros(srows,scols,dims);

[X, V, metric] = ADMM_for_NLRT(Y,gamma,mn_cell,bparams,A,AT,P,PT,shifted_mask, ...
                'initializer', {X,V,M},...
                'display',     true,...
                'orig',        orig,...
                'rank',        rank,...
                'niters',      niters);

step3_time = toc(step3_time);  % 计时
fprintf("step3_time:%f\n", step3_time);


tmymethod = toc(mytimestart);
t_part_mymethod = [step1_time, step2_time, step3_time];
fprintf('%s---NLRT_time:%fs\n', dataload_path, tmymethod);

% %% Save results
% coord_str = [num2str(site{s}(1)), '_', num2str(site{s}(2))];
% %save("./results/KAIST_results/Scene1_1_result.mat", 'orig', 'shifted_mask', 'meas', 'X', 'V', 'tmymethod', 't_part_mymethod', 'metric');
% filename1 = fullfile(save_path, [dname{i}, '_', coord_str, '.mat']);
% save(filename1, 'orig', 'shifted_mask', 'meas', 'X', 'V', 'tmymethod', 't_part_mymethod', 'metric');  % 保存特定变量
% save("./results/KAIST_results/Scene1_1_result.mat", 'orig', 'shifted_mask', 'meas', 'X', 'V', 'tmymethod', 't_part_mymethod', 'metric');
% filename = ['result of NLRT-gmmmask10,dataset =',dataname,'.xlsx'];
% tags = {'psnr','ssim'};
% T = array2table([metric(1,:)',metric(2,:)'],'VariableNames',tags);
% writetable(T,filename,'Sheet',dataname);
filename = sprintf('result of kaistnewdgdnlrt  dataset =%s k =%d.xlsx',strjoin(dname(i)),k);
tags = {'psnr','ssim'};
T = array2table([metric(1,:)',metric(2,:)'],'VariableNames',tags);
writetable(T,filename,'Sheet',dataname);
end
end
end
end
%end
