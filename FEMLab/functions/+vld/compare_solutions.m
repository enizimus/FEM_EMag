function compare_solutions(files, N, optProb, mshType, doPrint, printFormat)

if(nargin < 6 || isempty(printFormat)), printFormat = '-dpng'; end
if(nargin < 5 || isempty(doPrint)), doPrint = 0; end

load(files.respth, 'xlims', 'ylims')

if(strcmp(optProb.problemClass, 'Mstatic'))
    if(strcmp(optProb.symmetry, 'planar'))
        if(strcmp(mshType.edge, 'circ'))
            msh_r = 0.5; % radius of circular mesh
            phi = pi/4;
            r = linspace(0, msh_r, N);
            xl = r*cos(phi);
            yl = r*sin(phi);
        elseif(strcmp(mshType.edge, 'rect'))
            xl = linspace(0, 1, N);
            yl = xl;
            r = sqrt(xl.^2 + yl.^2);
        end
    else
        
        xl = linspace(0, 2, N);
        r = xl;
        yl = ones(size(xl))*(ylims(2)/2);
    end
    
    B_exact = vld.calc_exact_B(N, xl, yl, r, optProb.valid, mshType);
    [B_fem,~,~] = slv.evalB(files, xl, yl);
    %     B_ef = vld.get_elefant_B('long_solenoid_0515');
    
    %     abserr_fem = abs(B_exact - B_fem);%./B_exact * 100;
    %     abserr_elf = abs(B_exact - B_ef);
    %
    %     errsum_fem = sum(abserr_fem);
    %     errsum_elf = sum(abserr_elf);
    
    rel_err = abs(B_exact - B_fem);%./max(B_exact, B_fem)*100;
    
    figure
    subplot(2,1,1)
    plot(r, B_exact, 'linewidth', 1.2)
    hold on
    grid on
    plot(r, B_fem, 'linewidth', 1.2)
    %     plot(r, B_ef, 'linewidth', 1.2)
    title({'Comparison : B field exact values and FEM values', ['N = ', num2str(N)]})
    xlabel('r')
    ylabel('|B| [T]')
    legend('B-Exact', 'B-FEM', 'B-Elefant')%, 'location', 'eastoutside')
    xlim([min(r) 1])
    hold off
    
%     if(doPrint)
%         print(files.pltpth_valid1, printFormat, '-r300')
%     end
    
%     figure
subplot(2,1,2)
    plot(r, rel_err, 'linewidth', 1.2);
%     hold on
    grid on
%     plot(r, abserr_elf, 'linewidth', 1.2);
    title({'Absolute error between the exact field and the FEM values', ''})
    xlabel('r')
    ylabel('Error [T]')
    xlim([min(r) 1])
%     legend(['B-FEM errsum = ' num2str(errsum)]) % ['B-Elefant errsum = ' num2str(errsum_elf)]
    hold off
    
    set(gcf,'Position',[744 495 777 555])
    
    if(doPrint)
        print(files.pltpth_valid2, '-dpng', '-r300')
    end
    
    
    
    
else % electrostatic case validation, uniformly charged sphere
    xl = linspace(0, 1, N);
    yl = xl;
    r = sqrt(xl.^2 + yl.^2);
    
    E_exact = vld.calc_exact_E(N, r);
    E_fem = slv.calcE(files);
    
    figure
    plot(r, E_exact, 'linewidth', 1.2)
    hold on
    grid on
    plot(r, E_fem, 'linewidth', 1.2)
    % plot(r, B_ef, 'linewidth', 1.2)
    title({'Comparison : B field exact values and FEM values', ['N = ', num2str(N)]})
    xlabel('r')
    ylabel('|B| [T]')
    legend('B-Exact', 'B-FEM', 'B-Elefant', 'location', 'eastoutside')
    xlim([min(r) max(r)])
    hold off
    
    if(doPrint)
        print(files.pltpth_valid1, printFormat, '-r300')
    end
end

