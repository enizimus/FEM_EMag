function [f_Ex, f_Ey] = get_E_fun(optProb)

f_Ex = @(A, ABC) -A'*ABC(1,:)';
f_Ey = @(A, ABC, ~, ~) -A'*ABC(2,:)';
