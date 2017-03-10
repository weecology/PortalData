import csv
import re

csvfile = open('Portal_plant_1981_2015.csv','r')
csvfile1= open('Portal_plant_2015_present.csv','r')
updated = open('Portal_plants.csv','w')
updated_writer = csv.writer(updated,lineterminator='\n')
updated_writer.writerow(["year","season","plot","quadrant","species","abundance","cover","cf"])
reader=csv.reader(csvfile)
reader1=csv.reader(csvfile1)

#updation from Portal_plant_1981_2015

rownum=0
for line in reader:
    if rownum==0:
        pass
    else:
        updated_writer.writerow([line[0],line[1],line[2],line[3],line[4],line[5],"",""])
    rownum+=1
print repr(rownum)+" lines updated from file Portal_plant_1981_2015.csv"

#updatio from Portal_plant_2015_present

rownum1=0
for line in reader1:
    if rownum1==0:
        pass
    else:
        updated_writer.writerow([line[0],line[1],line[2],line[3],line[4],line[5],line[6],line[7]])
    rownum1+=1
print repr(rownum1)+" lines updated from file Portal_plant_1981_2015.csv"
csvfile.close()
csvfile1.close()
updated.close()
