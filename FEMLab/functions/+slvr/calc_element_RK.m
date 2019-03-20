function [K,R,U,n] = calc_element_RK(fun_K, fun_R, f_K, f_R, nodes, nodes_prop, element, regions_c, elem_tag)

mu_0 = regions_c.mu_0;

[U, i_k, i_n] = slvr.set_known_u([element.nodes], nodes_prop, regions_c);

if(regions_c.is_source(elem_tag)) %if region is source
    f = regions_c.get_param(elem_tag); % Stromdichte J
    k1 = 1/mu_0; % \mu of copper of source
else
    f = 0;
    k1 = 1/(regions_c.get_param(elem_tag)*mu_0); % 1/(mu_r * mu_0)
end

k = [k1 k1];
[abc, A] = slvr.calc_abc(nodes, [element.nodes]);
[xe, ye] = hlp.get_element_xy(nodes, [element.nodes]);

K = zeros(3,3);
R_p = zeros(3,1); 

for i=1:3
    for j=1:3
        K(i,j) = fun_K(A, k, abc, f_K, xe, ye, i, j);
    end
    R_p(i) = fun_R(A, abc(:,i), f, f_R, xe, ye);
end

K_len = max([length(i_k), length(i_n)]);

R_temp = zeros(3,1);
R_temp(i_n) = U(i_k)'*reshape(K(i_n, i_k),[K_len, 1]);
R = R_p - R_temp;
n = i_n;



