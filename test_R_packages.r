# Test that these preinstalled R packages are available and functional

library("animation")
library("cowplot")
library("ggdist")
library("FactoMineR")
library("psych")
#library("magick")

# These packages are not available through conda; check that they can
# be installed by the user:

## Default repo
local({r <- getOption("repos")
       r["CRAN"] <- "https://cloud.r-project.org" 
       options(repos=r)
})

install.packages("psycho",    keep_outputs=TRUE, verbose=TRUE)
install.packages("rAverage",  keep_outputs=TRUE, verbose=TRUE)
install.packages("RWiener",   keep_outputs=TRUE, verbose=TRUE)
install.packages("metRology", keep_outputs=TRUE, verbose=TRUE)
# added for the school
install.packages("ape")
install.packages("phangorn")
install.packages("https://raw.githubusercontent.com/sgearle/bugwas/master/build/bugwas_1.0.tar.gz", repos=NULL, type="source")

# Test that these manually installed R packages are available and functional

library("psycho")
library("rAverage")
library("RWiener")
library("metRology")
# add test 
library("ape")
library("phangorn")

