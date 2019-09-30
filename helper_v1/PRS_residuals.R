suppressMessages(require(argparse))
source('PRS_residuals_misc.R')

PRS_residuals <- function(
    out_f, phe_f, score_f, keep_f = NULL,
    plot_width = 10, plot_height = 5
){
    data <- read_data(phe_f, score_f, keep_f)
    p_combined <- grid.arrange(
        data %>% plot_scatter()   + labs(title='A.  Observed phenotype vs. Polygenic prediction') , 
        data %>% plot_residuals() + labs(title='B.  Residuals from the polygenic prediction'), 
        widths = c(1, 1), nrow = 1
    )
    ggsave(out_f, p_combined, width=plot_width, height=plot_height) 
}

PRS_residuals_parser <- function(){
    parser <- ArgumentParser(description='snpnet fit wrapper')
    parser$add_argument('-o', metavar='O', required=TRUE, help='Output image file')
    parser$add_argument('-p', metavar='P', required=TRUE, help='Phenotype file')
    parser$add_argument('-s', metavar='S', required=TRUE, help='Score file (from plink2 --score)')
    parser$add_argument('-k', metavar='K', default=NULL, help='Keep file')
    parser$add_argument('-w', metavar='w', default=10, help='plot width')
    parser$add_argument('-h', metavar='h', default=5,  help='plot height')
    return(parser)
}

PRS_residuals_main <- function(args){
    PRS_residuals(
        out_f       = args$o, 
        phe_f       = args$p, 
        score_f     = args$s, 
        keep_f      = args$k,
        plot_width  = args$w, 
        plot_height = args$h
    )
}

# parse
cmdargs <- commandArgs(TRUE)
parser <- PRS_residuals_parser()
args <- parser$parse_args(cmdargs)
print(args)
PRS_residuals_main(args)


