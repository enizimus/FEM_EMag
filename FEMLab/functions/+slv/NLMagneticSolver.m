function NLMagneticSolver(app)
close all
clc

if strcmp(app.settings.problemClass, app.MagnetostaticButton.Text)
    fprintf("Using nonlinear magnetic solver.\n")
    app.settings.isNonlinear = 1;
    solve(app);
else
    uialert(app.FEMLabUIFigure, ...
        "Solver can only be used for magnetostatic problems.", ...
        "Wrong problem type.")
end

end

function solve(app)
bgcolor = [169,169,169] / 255;
% Prepare everything for solver-algorithm
 nlSolverSetup(app);

% Get hysteresis data
% Load here and not in updateMaterialData to avoid loading in every
% iteration
BHCurveData = jsondecode(fileread(fullfile("AppFiles", "nlSolverBHCurves", ...
    "muRCurves.json")));

% Iterate until solution converges
iteration_counter = 0;
while(~convergenceCondition(app))
    
    fprintf("================================================================================\n")
    fprintf("                               Iteration %-5u\n", ...
        iteration_counter)
    fprintf("================================================================================\n")
    
    S = load(app.files.respth, "Bp");
    Bp_old_nl = S.Bp;
    save(app.files.respth, "Bp_old_nl", "-append");
    
    msh.prepFieldData(app.files, app.settings);
    
    updateMaterialData(app, BHCurveData);
    
    slv.calcA(app.files, app.settings);
    A = slv.evalA(app.files, app.settings);
    save(app.files.respth, 'A', '-append');
    slv.calcBH(app.files, app.settings); 
    
    selectedButton = app.FieldTButtonGroup.SelectedObject;
    app.plotSettings.field = selectedButton.Text;
            
    
    
    S = load(app.files.respth, "H_abs_mean", "triangles", "nl_material_params", "x", "y");
    
    tri = triangulation(S.triangles(:, 1 : 3), S.x, S.y, zeros(length(S.x), 1));
    tri_centers = incenter(tri);
    cx = tri_centers(:, 1);
    cy = tri_centers(:, 2);
    
    B_abs_mean = S.H_abs_mean .* S.nl_material_params .* (4e-7 * pi);
    
    if iteration_counter > 0
%         figure()
%         colormap
%         trimesh(tri, 'FaceColor', 'none', 'EdgeColor', 'black');
%         hold on
%         scatter3(cx, cy, S.H_abs_mean, 20, S.H_abs_mean, 'filled');
%         grid off
%         xlabel("x-axis in m")
%         ylabel("y-axis in m")
%         title("|H_{mean}|")
%         view(2);
%         colorbar
%         
%         figure()
%         colormap
%         trimesh(tri, 'FaceColor', 'none', 'EdgeColor', 'black');
%         hold on
%         scatter3(cx, cy, B_abs_mean, 20, B_abs_mean, 'filled');
%         grid off
%         xlabel("x-axis in m")
%         ylabel("y-axis in m")
%         title("|B_{mean}|")
%         view(2);
%         colorbar
    end
    
    
    
    figure()
    trimesh(tri, 'FaceColor', 'none', 'EdgeColor', 'black');
    hold on
    scatter3(cx, cy, S.nl_material_params, 20, S.nl_material_params, 'filled');
    grid off
    xlabel("x-axis in m")
    ylabel("y-axis in m")
    title(sprintf("|\\mu_r| per element, i = %d", iteration_counter))
    view(2);
    colorbar
    set(gca,'color',bgcolor)
    
%     app.files.pltpthAbs = fullfile(app.files.pltpth, sprintf("B_NL_i=%d",iteration_counter));
%     gfx.display(app.files, app.settings, 'H', 'type', 'abstri',...
%         'savePlot', false, 'fieldLinesOn', true, ...
%         'nCont', app.plotSettings.nCont, 'res', app.plotSettings.res, 'format', app.plotSettings.format)
    gfx.display(app.files, app.settings, 'B', 'type', 'abstri',...
        'savePlot', false, 'fieldLinesOn', true, ...
        'nCont', app.plotSettings.nCont, 'res', app.plotSettings.res, 'format', app.plotSettings.format)
    
    %keyboard
    
    iteration_counter = iteration_counter + 1;
    %S = load(app.files.respth);
    %keyboard
end
end

function nlSolverSetup(app)
    ProjectData = load(app.files.respth);
    
    Hp = zeros(ProjectData.nNodes, 1);
    Bp_old_nl = realmax * ones(ProjectData.nNodes, 1);
    Bp = zeros(ProjectData.nNodes, 1);
    
    save(app.files.respth, "Hp", "Bp", "Bp_old_nl", '-append');
    
end

function updateMaterialData(app, material_data)
% \brief Caluclate mean-values of magnetic-flux-densities in single
%        elements and derive the relative permeability in each element
%        from B-H-curve of corresponding material curve.
%
%


S = load(app.files.respth, "x", ...          % x-coordinates of nodes
                           "y", ...          % y-coordinates of nodes
                           "triangles", ...  % Triangle nodes
                           "nNodes", ...     % Total number of nodes
                           "regsTris", ...   % Region tags of triangles
                           "regSet");        % Region data (material, source, ...)


x_nodes = S.x;
y_nodes = S.y;
triangle_nodes = S.triangles;
[N_triangles, ~] = size(triangle_nodes);
triangle_region_tags = S.regsTris;
regions = S.regSet;


S = load(app.files.respth, "Hp");
H_abs_nodes = S.Hp;
% Calculate flux-density mean-values within each triangle
H_abs_mean = calculate_field_strength_means(x_nodes, y_nodes, ...
H_abs_nodes, triangle_nodes, app.settings);



% =========== Derive relative permebility via material-curve =============
surface_regions = regions([regions.dim] == 2);
N_surface_regions = length(surface_regions);

nl_material_params = zeros(N_triangles, 1); % Allocation of material data
                             



for k = 1 : N_surface_regions
    current_region_tag = surface_regions(k).id;
    current_material_curve = surface_regions(k).matProp;
    H_data = material_data.data(current_material_curve).H;
    mu_r_data = material_data.data(current_material_curve).muR;
    
    idx = triangle_region_tags == current_region_tag;
    
    nl_material_params(idx) = mu_r_spline(H_abs_mean(idx), H_data, mu_r_data);
    if current_material_curve > 1
        %figure()
        %semilogx(H_data, mu_r_data)
        %hold on
        %semilogx(H_abs_mean(idx), nl_material_params(idx), 'ro')
        %keyboard
    end
end
save(app.files.respth, "nl_material_params", "H_abs_mean", "-append")
end

function mu_r_sim = mu_r_spline(H_sim, H_curve, mu_r_curve)
    mu_r_sim = spline(H_curve, mu_r_curve, H_sim);
    
    
    % Extrapolate mu_r-curve by constant values
    max_H_curve = max(H_curve);
    min_H_curve = min(H_curve);
    
    mu_r_sim(H_sim >= max_H_curve) = mu_r_curve(end);
    mu_r_sim(H_sim <= min_H_curve) = mu_r_curve(1);
end

function H_abs_mean = calculate_field_strength_means(x_nodes, y_nodes, ...
    H_abs_nodes, triangle_nodes, settings)

[N_triangles, N_triangle_nodes] = size(triangle_nodes);

% Allocate memory for flux-density mean-values
H_abs_mean = zeros(N_triangles, 1); 

% Gauss-integration parameters
gauss_integration_data = slv.gaussIntData();
gauss_weights = gauss_integration_data(:, 3);
gauss_x = gauss_integration_data(:, 1);
gauss_y = gauss_integration_data(:, 2);
[N_integration_points, ~] = size(gauss_integration_data);


% Get formfunctions and corresponding ABC-values
formfun = slv.getFuns("formfun", settings);
formfun_abcs = slv.getAbcsXiEta(settings);


% =========== Field strength integration within each triangle ============
%
% Calculate
%
%   int(H(x,y) dx dy) / A
%
% within each triangle, with A being the triangle area.
%
% This is numerically done by Gauss-integration:
%
%   int(H(x,y) dx dy) = int(H(xi,eta) det(J) dXi dEta ) = 
%   int( sum(Bl Nl(xi, eta)) det(J) dXi dEta ) =
%   sum( Hl sum( wm  N(xi_m, eta_m) det(J)(xi_m, eta_m) ))  
%


% Iteration over triangles
for k = 1 : N_triangles
    current_triangle_nodes = triangle_nodes(k, :);
    xk = x_nodes(current_triangle_nodes);
    yk = y_nodes(current_triangle_nodes);
    H_abs_k = H_abs_nodes(current_triangle_nodes);
    
    H_abs_int = 0; % Integral of flux density over triangle area
    
    % Iterate over triangle nodes
    for l = 1 : N_triangle_nodes
        detJ_vec = slv.calcDetJXiEta(settings, gauss_x, gauss_y, xk, yk);
        
        % Gauss-integration of Hl * Nl(xi,eta) * det(J)
        for m = 1 : N_integration_points
            H_abs_int = ...
                H_abs_int + ...   % Sum-value
                H_abs_k(l) * ...  % Field-strength at current node
                gauss_weights(m) * ... % Gauss-weight at current point
                ... % Formfunction of node l at current Gauss-point
                formfun(gauss_x(m), gauss_y(m), formfun_abcs(l, :)') * ...
                ... % Jacobi-determinant value at current Gauss-point
                detJ_vec(m);
        end
        
        % Triangle area:
        % int(dx dy) = int(det(J) dXi dEta) = 
        % sum( wk * det(J)(xi_k, eta_k) )
        current_triangle_area = gauss_weights(:)' * detJ_vec(:);
        
        % Calculation of actual mean value
        H_abs_mean(k) = H_abs_int / current_triangle_area;  
    end
    
end

end

function ret = convergenceCondition(app)
    S = load(app.files.respth, "Bp", "Bp_old_nl");
    B_new = S.Bp(:);
    B_old = S.Bp_old_nl(:);
    
    diff_B = abs(B_new - B_old);
    diff_B_rel = diff_B ./ B_old;
    
    diff_B_rel_max = max(diff_B_rel);
    diff_B_int = sum(diff_B_rel) / length(B_new);
    
    fprintf("\nNL-solver stats:\n")
    fprintf("----------------\n")
    fprintf("\tBmax : %e\n", max(B_new))
    fprintf("\tDiff max: %e\nDiff int: %e\n\n", diff_B_rel_max, diff_B_int);
    
    ret = (diff_B_rel_max < 0.01) || max(diff_B) < 0.01;
end

