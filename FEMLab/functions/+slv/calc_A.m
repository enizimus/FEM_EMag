function calc_A(files, optProb)
disp('-Setting up element matrices and calculating A')
tic

load(files.respth, 'elements', 'regions_c', 'n_nodes', 'n_elements',...
    'nodes_prop', 'element_r', 'n_tri', 'n_lines', 'triangles', 'x', 'y')

[f_K, f_R] = slv.get_funs('element', optProb);
[fun_K, fun_R] = slv.get_funs('quadrature', optProb);
[tri_x, tri_y] = msh.get_tri_xy(triangles, x, y, n_tri);
tri_area = util.calc_tri_area(tri_x, tri_y, n_tri);
ABCs = slv.calc_abcs(tri_x, tri_y, n_tri, tri_area);
[elem_params, sour_params] = msh.get_elem_params(optProb, element_r, regions_c);
elems = reshape([elements(n_lines+1:end).nodes], [3 n_elements-n_lines])';
[Uk, Ik] = slv.setup_known_U(elems, n_tri, nodes_prop, regions_c);

K = spalloc(n_nodes, n_nodes, 6*n_nodes);
R = zeros(n_nodes,1);

for i_el = n_lines+1:n_elements
    i_tri = i_el-n_lines;
    abc = reshape(ABCs(i_tri,:,:), [3,3]);

    [tK, tR, tU, tn] = ... % U, fun_K, fun_R, f_K, f_R, A, abc, xe, ye, k1, f, I)
        slv.calc_element_RK(Uk(i_tri,:)', fun_K, fun_R, f_K, f_R, tri_area(i_tri),abc,...
        tri_x(i_tri,:), tri_y(i_tri,:), elem_params(i_el), sour_params(i_el), Ik(i_tri,:));
    
    i_N = elements(i_el).nodes(tn);
    
    K(i_N, i_N) = K(i_N, i_N) + tK(tn, tn);
    R(i_N) = R(i_N) + tR(tn);
    
    elements(i_el).K = tK(tn, tn);
    elements(i_el).R = tR(tn);
    elements(i_el).U = tU;
    
end

Ap = zeros(n_nodes, 1);

I = any(K,2);
u_unknown = I;
u_known = ~I;
K = K(I,:);
R = R(I);
I = any(K,1);
K = K(:,I);

U_known = slv.get_known_U(u_known, regions_c);
U_unknown = K\R;
Ap(u_unknown) = U_unknown;
Ap(u_known) = U_known;

% figure;surface(1:size(K,1),size(K,1):-1:1,K,K);colormap(util.bluewhitered);shading flat 
% eigenvals = eig(full(K));
% condition_number = max(abs(eigenvals))/min(abs(eigenvals));
% disp(['Condition Number: ',num2str(condition_number)]);

save(files.respth, 'elements', 'Ap', 'K', 'R', 'tri_area', 'ABCs', '-append');
disp(['  Finished (Elapsed time : ', num2str(toc) ' s)'])
end