These scripts are based on Speedtest.net CLI client
They are meant to be run on the local endpoint
Can be combined to export the reseults to f.ex Azure blob storage with AzCopy exports to create a home network monitoring solution
Along with adding periodic daily task scheduler checks to see if the user is in office network subnet or in any other network 
  -> if in office no scan 
  -> if at other location -> scan
