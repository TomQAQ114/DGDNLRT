function [mu1, mu2, sigma1, sigma2, fitted_mask] = fit_GMM_mask(mask)

% 计算灰度直方图
[counts, bins] = imhist(mask);
bins = bins(counts > 0); % 只取有像素的灰度级
counts = counts(counts > 0);


% 定义双高斯拟合模型
doubleGaussian = @(a1, b1, c1, a2, b2, c2, x) ...
    a1 * exp(-((x - b1)/c1).^2) + a2 * exp(-((x - b2)/c2).^2);
total_area = sum(counts) * (bins(2) - bins(1));

% 初始参数猜测（根据直方图形状调整）
initialGuess = [max(counts), 0.2, 0.1, max(counts), 0.6, 0.1]; % 示例初始值

% 使用lsqcurvefit进行非线性最小二乘拟合
fittedParams = lsqcurvefit(@(params, x) doubleGaussian(...
    params(1), params(2), params(3), params(4), params(5), params(6), x), ...
    initialGuess, bins, counts, [], [], optimset('Display','off'));

% 提取拟合参数
A1 = fittedParams(1);
mu1 = fittedParams(2);
sigma1 = fittedParams(3);
A2 = fittedParams(4);
mu2 = fittedParams(5);
sigma2 = fittedParams(6);

% 计算拟合曲线的总面积
x_fine = linspace(0, 1, 1000); % 更精细的x轴采样
fitted_curve_fine = doubleGaussian(A1, mu1, sigma1, A2, mu2, sigma2, x_fine);
fitted_area = trapz(x_fine, fitted_curve_fine);

% 归一化拟合曲线（使其积分等于1）
normalization_factor = fitted_area;
a1_normalized = A1 / normalization_factor;
a2_normalized = A2 / normalization_factor;

% 生成归一化后的拟合曲线
fittedCurve_normalized = doubleGaussian(...
    a1_normalized, mu1, sigma1, a2_normalized, mu2, sigma2, bins);

% 绘制拟合前后的对比图
figure('Position', [100, 100, 1200, 500]);

% 原始直方图
subplot(1, 2, 1);
bar(bins, counts/total_area, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none');
title('Original Normalized Grayscale Histogram');
xlabel('Normalized Gray Level (0-1)');
ylabel('Probability Density');
xlim([0 1]);
grid on;

% 拟合后的直方图
subplot(1, 2, 2);
bar(bins, counts/total_area, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on;
plot(bins, fittedCurve_normalized, 'r-', 'LineWidth', 2);
title('Fitted Double Gaussian Histogram (Normalized)');
xlabel('Normalized Gray Level (0-1)');
ylabel('Probability Density');
legend('Original', 'Fitted Curve');
xlim([0 1]);
grid on;

% 输出拟合参数
fprintf('双高斯拟合参数:\n');
fprintf('第一个高斯分量: 振幅 = %.4f, 均值 = %.4f, 标准差 = %.4f\n', a1_normalized, mu1, sigma1);
fprintf('第二个高斯分量: 振幅 = %.4f, 均值 = %.4f, 标准差 = %.4f\n', a2_normalized, mu2, sigma2);
fprintf('均值之和 = %.4f, 方差之和 = %.4f\n', mu1+mu2, sigma1^2+sigma2^2);

% 生成拟合后的mask图像
% 这里我们创建一个新的图像，其像素值按照拟合的双高斯分布生成
% 首先创建一个与原始图像大小相同的随机矩阵
random_matrix = rand(size(mask));

% 计算累积分布函数(CDF)
cdf_values = cumtrapz(x_fine, doubleGaussian(...
    a1_normalized, mu1, sigma1, a2_normalized, mu2, sigma2, x_fine));
cdf_values = cdf_values / max(cdf_values); % 归一化到[0,1]

% 使用逆变换采样方法生成符合双高斯分布的随机变量
fitted_mask = interp1(cdf_values, x_fine, random_matrix, 'linear', 'extrap');
fitted_mask = max(0, min(1, fitted_mask)); % 确保值在[0,1]范围内
% matFilePath = fullfile('D:\desktop\GMM-GAPTV\fitted_masks', 'fitted_mask1.mat');
% save(matFilePath, 'fitted_mask')

% 显示原始图像和拟合后的mask图像
figure('Position', [100, 100, 1200, 500]);

subplot(1, 2, 1);
imshow(mask);
title('Original Image');

subplot(1, 2, 2);
imshow(fitted_mask);
title('Fitted Mask Image');

% 读取灰度图像
I1 = mask;  
I2 = fitted_mask;

figure;
subplot(2,2,1);
imshow(I1);
title('原始灰度图像');

subplot(2,2,2);
imhist(I1);
title('灰度直方图');
xlabel('灰度值');
ylabel('像素个数');

subplot(2,2,3);
imshow(I2);
title('拟合灰度图像');

subplot(2,2,4);
imhist(I2);
title('灰度直方图');
xlabel('灰度值');
ylabel('像素个数');
close all
end