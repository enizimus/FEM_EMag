function calc_tri_B(files, prob_opt)

load(files.respth, 'U', 'triangles', 'nodes', 'n_nodes')

n_tri = length(triangles);
Bc = zeros(1,n_tri);
Bcx = zeros(1,n_tri);
Bcy = zeros(1,n_tri);
nodes_Bc = zeros(n_tri, 2);

[f_Bx, f_By] = slvr.get_B_fun(prob_opt);

for i_tri = 1:n_tri
   
    x = [nodes(triangles(i_tri,:)).x];
    y = [nodes(triangles(i_tri,:)).y];
    ABC = slvr.solve_abc(x,y);
    nodes_Bc(i_tri, :) = [sum(x)/3, sum(y)/3];
    
    cBy = f_By(U(triangles(i_tri,:)), ABC, x, y);
    cBx = f_Bx(U(triangles(i_tri,:)), ABC);
    
    Bcx(i_tri) = cBx;
    Bcy(i_tri) = cBy;
    Bc(i_tri) = sqrt(cBx^2 + cBy^2);
    
end

save(files.respth, 'Bc', 'Bcx', 'Bcy', 'nodes_Bc', '-append')

end