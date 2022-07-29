% function that will replace round because in Matlab versions prior to
% R2014b, round only took one arg
% h/t Fran from this discussion:
% https://www.mathworks.com/matlabcentral/newsreader/view_thread/339292
function x = roundp(x,n)
    x=round(x*10^n)/(10^n);
end