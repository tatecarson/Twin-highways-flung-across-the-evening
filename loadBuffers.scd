//load buffers
~parentPath = PathName(thisProcess.nowExecutingPath).parentPath;
~bufPath = ~parentPath ++ "samples";

~makeBuffers = {
  b = Dictionary.new;
  PathName(~bufPath).entries.do{
    arg subfolder;
    b.add(
      subfolder.folderName.asSymbol ->
      Array.fill(
        subfolder.entries.size,
        {
          arg i;
          Buffer.read(s, subfolder.entries[i].fullPath);
        }
      )
    );
  };
};

~makeBuffers.value;
~ssize = b[\cuts].size;
