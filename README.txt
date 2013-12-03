In order to get online data from Artinis Oxymon to a Field Trip buffer
do the following:

1. Put the files in your "../buffer_bci/dataAqc/" folder
2. Start Oxymon measurement
3. Run startNirs.sh
4. In the file chooser that pops up navigate to where your Oxymon measurement file is and select the .oxy3.tmp file and click open
5. The script will now read the temp file and feed each line of data to the buffer, 
	each line contains 8 channels of AD values and 16 channels of OD values