[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)
![gplogo2](gplogo2.png) - GenePattern-Tools
==========

<b>IMPORTANT NOTE: This is not a Broad Institute repository ! Please refer to the Broad pages for official GenePattern information.</b>

©GenePattern is a product of the [Broad Institute](http://software.broadinstitute.org/cancer/software/genepattern)

*All tools presented below have only been tested by me and may contain bugs, please let me know if you find some.

Please refer to the accompanying **[wiki](https://github.com/Nucleomics-VIB/genepattern-tools/wiki)** for examples and workflows.

## **scripts**

They were made to perform tasks not possible using the GenePattern GUI. <i>Specific features used in our code depend on the presence of executables or system resources that may be absent on your server.</i>

### **example**

The script **[GP_cliApp-wrapper.pl](scripts/GP_cliApp-wrapper.pl)** is derived from GenePattern provided wrappers and offers basic functionalities needed to create a perl wrapper with IO and error control. You can use it as start point to develop standard wrappers of your own.

## **modules**

You will find in that folder the zip archives of our modules that can be imported in your GP instance. Some module include a wrapper script (see comments above) while others rely solely on the GUI and on dependencies (to be!) installed on the server.

### **module Info**

The module **[Picard.2.template.v1.0.zip](https://github.com/Nucleomics-VIB/genepattern-tools/blob/master/modules/Picard.2.template.v1.0.zip?raw=true)** can be cloned and used as basis for various Picard modules. It includes recurrent options and validation arguments often combined to picard commands.

The module **[Picard.2.CollectMultipleMetrics.v0.4.2.zip](https://github.com/Nucleomics-VIB/genepattern-tools/blob/master/modules/Picard.2.CollectMultipleMetrics.v0.4.2.zip?raw=true)** uses only the GP module GUI to launch Picard CollectMultipleMetrics (2.10.x) multiple QC checks on a sorted SAM or BAM file (thanks to Peter Carr from the GenePattern support team for his help setting this tricky module up).

## **pipelines**

**Pipelines** are built from modules and chain them in a l;ogical order to simplify complex tasks. The second module takes its input from the results of the first module. Etc


<hr>

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

<hr>

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
