%  Test for reading and writing of UFF files.
close all; clear; clc

% First, let's read all the data-sets from the dam0.unv file
[DS, Info, errmsg] = readuff('dam0.unv');

% Let's check what is the first data-set like
DS{1}

% Tolerance for rounding errors
tol = 1e-8;

% Iterate over all possible combinations to write UFF files
for isReal = [0,1]% real vs. complex
    for isUneven = [0,1]% even vs. uneven
        for isDouble = [0,1]% single vs. double
            for isBinary = [0,1]% binary vs. ascii
                DS_out = cell(size(DS));
                for i= 1: length(DS)
                    DS_out{i} = DS{i};
                    if isReal
                        DS_out{i}.measData = real(DS_out{i}.measData);
                    end
                    if isUneven
                        DS_out{i}.x(end) = DS_out{i}.x(end)*1.1;
                    end
                    if isDouble
                        DS_out{i}.precision = 'double';
                    else
                        DS_out{i}.precision = 'single';
                    end
                    if isBinary
                        DS_out{i}.binary = 1;
                    else
                        DS_out{i}.binary = 0;
                    end
                end
                % Now, let's write the whole thing back into the dam0_out.unv
                writeuff('dam0_out.unv', DS_out, 'replace');
                
                % Read in the same file again
                [DS_in, Info, errmsg] = readuff('dam0_out.unv');
                
                % Test whether its content is identical up to rounding
                % errors
                for  i= 1: length(DS)
                    e = norm(DS_out{i}.measData-DS_in{i}.measData);
                    if e > tol
                        warning('tolerance exceeded %s',e);
                    end
                end
            end
        end
    end
end