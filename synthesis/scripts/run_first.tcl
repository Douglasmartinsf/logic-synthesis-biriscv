#!/bin/bash
# loading modules

# Para executar o XCELIUM
#cd ${PROJECT_DIR}/frontend
### run HDL
#xrun -64bit -v200x -v93 ${HDL_DIR}/${DESIGNS}.vhd ${HDL_DIR}/Util_package.vhd ${HDL_DIR}/${DESIGNS}_tb.vhd -top ${DESIGNS}_tb -access +rwc -gui


# Para executar o GENUS
cd ${PROJECT_DIR}/synthesis/work
echo "${PROJECT_DIR}"
## apenas o programa
#genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus -overwrite
# programa e carrega script para síntese automatizada
genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus -overwrite -files ${PROJECT_DIR}/synthesis/scripts/${DESIGNS}.tcl



