function [bbox_out] = bbox2bbox(bbox_in,reverse)
% BBOX2BBOX(BBOX_IN) converts the conventional boundingbox description 
%   (left,top,WIDTH,HEIGHT) to actual boundingbox coordinates (left,top,RIGHT,BOTTOM).
%
% BBOX2BBOX(BBOX_IN,REVERSE) converts in the reverse direction if REVERSE = true.
%

reverse_dir = false;
if nargin>1
    reverse_dir = reverse;
end

szbb = size(bbox_in);
if szbb(1)~=4
    error('cant process bounding-box, size of first dimension is ~= 4, aborting...')
end

    bbox_out = bbox_in;

    if ~reverse_dir
        
        % right         <<  left    +   width
        bbox_out(3,:)   = bbox_in(1,:) + bbox_in(3,:);
        % bottom        <<  top     +   height
        bbox_out(4,:)   = bbox_in(2,:) + bbox_in(4,:);
        
    else
        
        % width         <<  right   -   left
        bbox_out(3,:)   = bbox_in(3,:) - bbox_in(1,:);
        % height        <<  bottom  -   top
        bbox_out(4,:)   = bbox_in(4,:) - bbox_in(2,:);
        
    end

end