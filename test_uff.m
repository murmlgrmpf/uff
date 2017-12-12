%  Test for reading and writing of UFF files.
clear;

% First, let's read all the data-sets from the dam0.unv file
[DS, Info, errmsg] = readuff('dam0.unv');

% Let's check what is the first data-set like
DS{1}

% Now, let's write the whole thing back into the dam0_out.unv
writeuff('dam0_out.unv', DS, 'replace');