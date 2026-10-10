function mask1 = save_gray_image_as_mat(imagePath, cropSize, cropPosition)

    if nargin < 1
        error('请提供图像文件路径');
    end
    if nargin < 2
        cropSize = 256;  % 默认裁剪大小为 256×256
    end
    if nargin < 3
        cropPosition = 'center';  % 默认居中裁剪
    end

    % 处理裁剪大小参数
    if isnumeric(cropSize) && numel(cropSize) == 1
        cropSize = [cropSize, cropSize];  % 支持单值输入
    elseif isnumeric(cropSize) && numel(cropSize) == 2
        % 支持二维数组输入
    else
        error('裁剪大小参数必须是数值标量或二维数值数组');
    end

    %% 1. 读入并灰度化
    img = imread(imagePath);
%     load(imagePath);
%     img = maskall(:,:,i);
    if ndims(img) == 3 && size(img,3) == 3
        img = rgb2gray(img);   % 彩色→灰度
    end

    %% 2. 尺寸检查
    [H, W] = size(img);
    if H < cropSize(1) || W < cropSize(2)
        error('图像尺寸至少为 %dx%d，当前为 %dx%d', cropSize(1), cropSize(2), H, W);
    end

    %% 3. 计算裁剪位置（支持多种方式）
    if isnumeric(cropPosition) && numel(cropPosition) == 2
        % 用户指定起始坐标 (y, x)
        y1 = cropPosition(1);
        x1 = cropPosition(2);
        
        % 检查坐标是否有效
        if y1 < 1 || x1 < 1 || y1 + cropSize(1) - 1 > H || x1 + cropSize(2) - 1 > W
            error('裁剪位置超出图像范围。图像大小为 %dx%d，裁剪大小为 %dx%d，起始位置为 (%d, %d)', ...
                H, W, cropSize(1), cropSize(2), y1, x1);
        end
        
    elseif ischar(cropPosition) || isstring(cropPosition)
        % 字符串指定的裁剪方式
        switch lower(char(cropPosition))
            case 'center'
                % 居中裁剪
                y1 = floor((H/2 - cropSize(1)/2)) + 1;
                x1 = floor((W/2 - cropSize(2)/2)) + 1;
                
            case 'random'
                % 随机裁剪
                y1 = randi([1, H - cropSize(1) + 1]);
                x1 = randi([1, W - cropSize(2) + 1]);
                
            case 'topleft'
                % 左上角裁剪
                y1 = 1;
                x1 = 1;
                
            case 'topright'
                % 右上角裁剪
                y1 = 1;
                x1 = W - cropSize(2) + 1;
                
            case 'bottomleft'
                % 左下角裁剪
                y1 = H - cropSize(1) + 1;
                x1 = 1;
                
            case 'bottomright'
                % 右下角裁剪
                y1 = H - cropSize(1) + 1;
                x1 = W - cropSize(2) + 1;
                
            otherwise
                error('不支持的裁剪方式: %s。支持: center, random, topleft, topright, bottomleft, bottomright', ...
                    char(cropPosition));
        end
    else
        error('裁剪位置参数必须是数值二维数组或字符串');
    end

    %% 4. 执行裁剪
    y2 = y1 + cropSize(1) - 1;
    x2 = x1 + cropSize(2) - 1;
    mask1 = img(y1:y2, x1:x2);
    mask1 = im2double(mask1);  % 转换为双精度
end



