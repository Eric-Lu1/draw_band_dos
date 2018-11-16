function draw_band_structure_dos(eigval_file, dos_file, pos_file, kpts_file)
%draw band structure and dos of a system, except for magnetism system
%   draw_band_structure_dos(eigval_file, dos_file, pos_file, kpts_file, have_pdos)
%   eigval_file: the path of EIGENVAL file
%   dos_file:   the path of DOSCAR file
%   pos_file:   the path of pos file
%   kpts_file:  the path of KPOINTS file, note that kpoints file must be
%   generated by ALFOW format.
%   have_pdos: true if you have set LORBIT=11 in INCAR;
%              false else.
%
%   Examples:
%
%       pat = 'band';
%       have_pdos = true;
%       eigval_file = fullfile(pat, 'EIGENVAL');
%       dos_file = fullfile(pat, 'DOSCAR');
%       pos_file = fullfile(pat, 'POSCAR');
%       kpts_file = fullfile(pat, 'KPOINTS');
%       draw_band_structure_dos(eigval_file, dos_file, pos_file, kpts_file)
%
%
%   See also draw_band_structure, draw_dos_element, draw_dos_pdos
[energy, kpoint] = read_eigenval(eigval_file);
E_fermi = get_fermi_from_doscar(dos_file);
if length(energy) > 1;
    error('Draw spined band structures are not supported here')
end
energy = energy{1};
[rec_k, sys_name] = read_recip(pos_file);
sys_name = deblank(sys_name);
for ii = 2:size(kpoint,1)
    kpoint(ii, 5) = norm((kpoint(ii-1,1:3)-kpoint(ii,1:3)) * rec_k);
end
kpoint(:,5) = cumsum(kpoint(:,5));
tmp_occupy = energy(:,2:2:end);
tmp_mean_occupy_up = mean(tmp_occupy,2);
q_up = find(abs(diff(tmp_mean_occupy_up))>0.4);
cbm_up = energy(q_up+1,1:2:end);
vbm_up = energy(q_up,1:2:end);
if E_fermi > max(vbm_up) % fermi level lies above vbm
    fermi_above = true;
    energy_gap = min(cbm_up) - max(vbm_up);
    energy = energy - max(vbm_up);
    [hsp, hsp_label, node] = read_high_sym_point(kpts_file);
else
    fermi_above = false;
    energy_gap = 0;
    energy = energy - E_fermi;
    [hsp, hsp_label, node] = read_high_sym_point(kpts_file);
    warning('fermi level lies in the valence bands')
end
figure
h1 = subplot(1,2,1);
h1_pos = get(h1,'position');
set(h1,'position',[h1_pos(1)+0.05 h1_pos(2:4)])
plot_band(kpoint, energy(:,1:2:end), hsp, hsp_label, node, sys_name, energy_gap,'k')
screen_size = get(0,'screensize');
set(gcf, 'Position',[0.8*screen_size(1:2)+100 0.8*screen_size(3:4)])
fid = fopen(dos_file, 'rt');
k = 1;
while feof(fid) == 0
    tline = fgetl(fid);
    if k == 6
        s = str2num(tline);
        break
    end
    k = k + 1;
end
fclose(fid);
h1_pos = get(h1,'position');
h2 = subplot(1,2,2);
set(h2, 'position', [h1_pos(1)+h1_pos(3) h1_pos(2) h1_pos(3) h1_pos(4)])
[sum_dos, p_dos] = read_doscar(dos_file);
[atom, num, sys_name] = read_element(pos_file);
n_pdos = size(p_dos,2);
if fermi_above;zero_point = E_fermi;else zero_point = s(4);end
switch n_pdos
    case {10, 17}
        element_dos_up = zeros(s(3), length(atom));
        seq = zeros(length(atom),2);seq(1,:) = [1 num(1)];
        for ik = 2:length(atom)
            seq(ik,:) = [sum(num(1:ik-1))+1 sum(num(1:ik))];
        end
        hold on
        sum_dos(:,1) = sum_dos(:,1) - zero_point;
        for ik = 1:length(atom)
            element_dos_up(:, ik) = sum(sum(p_dos(:,2:end,seq(ik,1):seq(ik,2)),2),3);
            color_ = rand(3,1);
            plot(element_dos_up(:,ik), sum_dos(:,1), 'color', color_)
        end
        plot(sum_dos(:,2), sum_dos(:,1), 'r','LineWidth', 2)
        ind = sum_dos(:,1) < 0;sum_dos = sum_dos(ind,:);
        patch([sum_dos(:,2);flipud(zeros(size(sum_dos,1),1))],...
            [sum_dos(:,1);flipud(sum_dos(:,1))],...
            [45 48 52]/255,...
            'FaceA',.2,'EdgeA',0);
        yval = get(h1,'Ytick');
        xval = get(h2,'Xtick');
        axis([xval(1) xval(end) yval(1) yval(end)])
        set(h2, 'XTickLabel',[], 'YTicKLabel',[])
        h = legend(atom{:},'Total DOS');set(h,'FontSize',18);
end
if p_dos == 0
    sum_dos(:,1) = sum_dos(:,1) - zero_point;
    plot(sum_dos(:,2), sum_dos(:,1), 'r','LineWidth', 2)
    ind = sum_dos(:,1) < 0;
    sum_dos = sum_dos(ind,:);
    patch([sum_dos(:,2);flipud(zeros(size(sum_dos,1),1))],...
        [sum_dos(:,1);flipud(sum_dos(:,1))],...
        [45 48 52]/255,...
        'FaceA',.2,'EdgeA',0);
    yval = get(h1,'Ytick');
    xval = get(h2,'Xtick');
    axis([xval(1) xval(end) yval(1) yval(end)])
    set(h2, 'XTickLabel',[], 'YTicKLabel',[])
    legend('Total DOS');
end
title(['DOS of ',deblank(sys_name)])
% yval = get(gca, 'ylim');
% text(0,0,'E_{fermi}')
% line([0, 0],[yval(1) yval(end)], 'linestyle','--')
