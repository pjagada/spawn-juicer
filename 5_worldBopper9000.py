import shutil
import glob
import os

# Edit this
INST_FOLDER = "C:/MultiMC/instances"

with open("bop.log", "w") as log:
    files = glob.glob(f'{INST_FOLDER}/*/.minecraft/saves/*')
    for f in files:
        if os.path.isdir(f) and ("New World" in f or "Speedrun #" in f):
            log.write("Deleting: " + f + "\n")
            shutil.rmtree(f)
        else:
            log.write("Skipping: " + f + "\n")