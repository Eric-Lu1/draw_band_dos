function draw_band_structure_two_spin(eigval_file, pos_file, kpts_file)
%draw band structure of a spined system
%   draw_band_structure(eigenval_file, doscar_file, pos_file, kpoints_file, n_band)
%   eigenval_file: the path of EIGENVAL file
%   doscar_file:   the path of DOSCAR file
%   pos_file:   the path of pos file
%   kpoints_file:  the path of KPOINTS file, note that kpoints file must be
%   generated by ALFOW format.
%   n_band:        the band number you want to plot
%
%   Examples:
%
%       eigenval_file = 'FM/EIGENVAL';
%       pos_file = 'FM/POSCAR';kpts_file = 'FM/KPOINTS';
%       draw_band_structure_two_spin(eigval_file, pos_file, kpts_file)
%
%
%   See also draw_band_structure_dos, draw_dos_element, draw_dos_pdos, draw_band_structure


[energy, kpoint] = read_eigenval(eigval_file);
energy_up = energy{1};
energy_down = energy{2};
tmp_occupy_up = energy_up(:,2:2:end);
tmp_occupy_down = energy_down(:,2:2:end);
tmp_mean_occupy_up = mean(tmp_occupy_up,2);
tmp_mean_occupy_down = mean(tmp_occupy_down,2);
q_up = find(abs(diff(tmp_mean_occupy_up))>0.8);
cbm_up = energy_up(q_up+1,1:2:end);
vbm_up = energy_up(q_up,1:2:end);
q_down = find(abs(diff(tmp_mean_occupy_down))>0.8);
cbm_down = energy_down(q_down+1,1:2:end);
vbm_down = energy_down(q_down,1:2:end);
[rec_k, sys_name] = read_recip(pos_file);
sys_name = deblank(sys_name);
for ii = 2:size(kpoint,1)
    kpoint(ii, 5) = norm((kpoint(ii-1,1:3)-kpoint(ii,1:3)) * rec_k);
end
kpoint(:,5) = cumsum(kpoint(:,5));
[hsp, hsp_label, node] = read_high_sym_point(kpts_file);
energy_gap = min(cbm_up) - max(vbm_up);
energy_up = energy_up - max(vbm_up);
figure
h1 = subplot(1,2,1);
h1_pos = get(h1,'position');

plot_band(kpoint, energy_up(:,1:2:end), hsp, hsp_label, node, sys_name, energy_gap,'k')

energy_gap = min(cbm_down) - max(vbm_down);
energy_down = energy_down - max(vbm_down);
h2 = subplot(1,2,2);
set(h2, 'position', [h1_pos(1)+h1_pos(3)+0.01 h1_pos(2) h1_pos(3) h1_pos(4)])
plot_band(kpoint, energy_down(:,1:2:end), hsp, hsp_label, node, sys_name, energy_gap,'r')
set(h2,'YTicklabel',[])