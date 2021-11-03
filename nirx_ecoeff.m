% PURPOSE: returns extinction coefficient for use in MBLL calculation from
% lookup tables, currently supports Cope, Moaveni, Prahl and Takatani
% (citations in mat file tables)
% 
% INPUT: wl, wavelength
%        table, 'string' (optional input, default is 'Moaveni'
% OUTPUT: ec, extinction coefficients for HbO & Hbr

% Main
function ec = nirx_ecoeff(wl,varargin)
    % defaults
    if nargin > 1
        table = varargin{1};
    else
        table = 'Moaveni';
    end
    [table_path,~,~] = fileparts(which('nirx_ecoeff.m'));
    
    switch table
        case 'Moaveni'
            load(fullfile(table_path,'templates','Moaveni_ecoeff.mat'));
        case 'Prahl'
            load(fullfile(table_path,'templates','Prahl_ecoeff.mat'));
        case 'Cope'
            load(fullfile(table_path,'templates','Cope_ecoeff.mat'));
        case 'Takatani'
            load(fullfile(table_path,'templates','Takatani_ecoeff.mat'));
        otherwise
            error('requested table does not exist!');
    end
    
    % find wavelengths (lambda), spline interpolate if not found
    ind =  find(ecoeffs(:,1) == wl);
    if ~isempty(ind)
        ec = ecoeffs(ind,2:3);
    else
        min_ecoeff = min(ecoeffs(:,1));
        max_ecoeff = max(ecoeffs(:,1));
        if wl > min_ecoeff && wl < max_ecoeff
            allwl = min_ecoeff:1:max_ecoeff;
            iec(:,1) = spline(ecoeffs(:,1),ecoeffs(:,2),allwl);
            iec(:,2) = spline(ecoeffs(:,1),ecoeffs(:,3),allwl);
            ec = iec(allwl == wl,:);
            fprintf('Wavelength not found in table.\nUsing interpolated values for %d nm\n',wl);
        else
            error('%d nm is outside range of requested table!',wl);
        end
    end
    fprintf('Citation:\n%s',citation);
        
end