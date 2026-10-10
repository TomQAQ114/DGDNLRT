function [A] = prox_tucker_4D(orig, rank)
%PROX_TUCKER_4D 计算4D张量的Tucker分解近似
%   输入:
%   orig: 4D张量
%   ranks: 各维度的Tucker秩向量，格式为[r1, r2, r3, r4]
%
%   输出:
%   A: 经过Tucker低秩近似后的4D张量

    % 将输入转换为张量对象
    orig = tensor(orig);
    
    % 使用Tucker-ALS算法进行分解
    % 'printitn', 0 表示不输出迭代信息
    T = tucker_als(orig, rank, 'printitn', 0);
    
    % 获取核心张量和因子矩阵
    core = double(T.core);
    U1 = double(T.U{1});
    U2 = double(T.U{2});
    U3 = double(T.U{3});
    U4 = double(T.U{4});
    
    % 重建近似张量
    % 方法1: 使用n模乘积直接计算
%     A = ttm(core, {U1, U2, U3, U4}, [1, 2, 3, 4]);
    A = double(T);
    
    % 或者方法2: 手动计算每个维度的乘积（更清晰但稍慢）
    % A = reconstruct_manual(core, U1, U2, U3, U4);
end