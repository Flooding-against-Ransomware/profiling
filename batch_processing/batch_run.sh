#!/bin/bash

DIRECTORY=${1:-"reports"}

mkdir $DIRECTORY/stage1 $DIRECTORY/stage2 $DIRECTORY/stage3 $DIRECTORY/stage4 $DIRECTORY/stage5
mv $DIRECTORY/*.json $DIRECTORY/stage1

ruby attack_profiler_for_folder.rb attack_profiler.rb base.json $DIRECTORY/stage1
mv $DIRECTORY/stage1/*-report.json $DIRECTORY/stage2

ruby report_analyser_for_folder.rb report_analyser.rb $DIRECTORY/stage2
mv $DIRECTORY/stage2/*-analysis.json $DIRECTORY/stage3

ruby analyser_aggregator.rb $DIRECTORY/stage3
mv $DIRECTORY/stage3/*-aggregatorOf*.json $DIRECTORY/stage4

ruby visual_analyser.rb $DIRECTORY/stage4/*.json
mv $DIRECTORY/stage4/*.pdf $DIRECTORY/stage5
rm _result.json