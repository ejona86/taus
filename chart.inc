;CHART_HORIZ = 1
.ifndef CHART_HORIZ
chartBarCount = 20
.else
chartBarCount = 12
.endif

.ifndef __CHARTSIMPORT
.import levelEffs
.import drawChartBackground
.import drawChartSprites
.import chartEffConvert
.endif
