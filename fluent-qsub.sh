#!/bin/bash
# Fluent case creation script. Takes a fluent .cas file, prepares it for submission and submits it to SGE

casefile=$1
if [ "$casefile" = "" ]; then
	echo "Casefile must be specified" 1>&2
	exit 1
fi

if [ "$2" = "" ]; then
	iterations="30000"
else
	iterations=$2
fi

casedir=$(echo $casefile | sed 's/\..*$//')

mkdir $casedir
if [ "$?" != "0" ]; then
	echo "Could not create case directory" 1>&2
	exit 1
fi

mv $casefile "$casedir/"
if [ "$?" != "0" ]; then
	echo "Could not locate / move case file" 1>&2
	exit 1
fi

cd $casedir

cat << EOF > $casedir.csh
#!/bin/bash
# use current working directory
#$ -cwd
# hours of runtime
#$ -l h_rt=48:00:00
#Nodes to run on and memory limit
#$ -l nodes=1 
#Folks to contact
#$ -M michael@tertheya.com -m beas
# define license and load module
module add ansys
export ANSYSLMD_LICENSE_FILE=1055@ansys-server1.leeds.ac.uk
# Launch the executable
fluent -g -i $casedir.jou 3ddp -sgeup -mpi=openmpi -rsh=ssh -affinity=off
EOF

cat << EOF > $casedir.jou
/file/read-case $casefile
/file/auto-save/data-frequency 100
/file/auto-save/retain-most-recent-files
y
/solve iter $iterations
/file/write-data $casedir.dat
y
/exit
y
EOF

qsub $casedir.csh
