function [top_ind_list, bottom_ind_list] = get_indexes_by_top_perc( samples, delta )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% assert ordinate in maniera decrescente
% 0 < delta < 1
n_el = length(samples);
n_top = ceil(n_el * delta);
%n_bottom = n_el - n_top;
top_ind_list = 1:n_top - 1;
bottom_ind_list = n_top:size(samples, 1);

end

