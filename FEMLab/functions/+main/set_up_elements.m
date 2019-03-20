function set_up_elements(files, prob_opt)

disp('-Calculating element matrices ...')
tic

load(files.respth, 'elements', 'regions_c', 'n_nodes', 'n_elements',...
    'nodes', 'nodes_prop', 'element_r')

i_elem = 1;

while(elements(i_elem).type == 1)
    i_elem = i_elem + 1;
end

[f_K, f_R] = slvr.get_element_fun(prob_opt);
[fun_K, fun_R] = slvr.get_integral_fun(prob_opt);

        
for i_el = i_elem:n_elements
    [elements(i_el).K, elements(i_el).R, elements(i_el).U, ...
        elements(i_el).n] = ...
        slvr.calc_element_RK(fun_K, fun_R, f_K, f_R, nodes, ...
        nodes_prop, elements(i_el), ...
        regions_c, element_r(i_el));
end


save(files.respth, 'elements', '-append');

disp(['  Finished (Elapsed time : ', num2str(toc) ' s)'])
end

