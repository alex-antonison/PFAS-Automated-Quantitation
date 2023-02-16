Processed Data
================
2023-02-14

# Logic Flow

``` r
DiagrammeR::grViz("digraph {

graph [layout = dot]

# define the global styles of the nodes. We can override these in box if we wish
node [shape = rectangle, style = filled, fillcolor = white]

sourceData [label = 'Raw Data from mass spec', shape = folder, fillcolor = Linen]
step1 [label = 'Convert Sheet seperated data into single table for calculations']
step2 [label = 'Calculate Cal Curve (see Cal Curve Caluclation Diagram)']

# edge definitions with the node IDs
sourceData -> step10 -> step20 -> step21 
}")
```

<div class="grViz html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-5ecf0ced77cd89fa87d2" style="width:672px;height:480px;"></div>
<script type="application/json" data-for="htmlwidget-5ecf0ced77cd89fa87d2">{"x":{"diagram":"digraph {\n\ngraph [layout = dot]\n\n# define the global styles of the nodes. We can override these in box if we wish\nnode [shape = rectangle, style = filled, fillcolor = white]\n\nsourceData [label = \"Raw Data from mass spec\", shape = folder, fillcolor = Linen]\nstep1 [label = \"Convert Sheet seperated data into single table for calculations\"]\nstep2 [label = \"Calculate Cal Curve (see Cal Curve Caluclation Diagram)\"]\n\n# edge definitions with the node IDs\nsourceData -> step10 -> step20 -> step21 \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script>

# Cal Curve Calculation

``` r
DiagrammeR::grViz("digraph {

graph [layout = dot]

# define the global styles of the nodes. We can override these in box if we wish
node [shape = rectangle, style = filled, fillcolor = white]

sourceData [label = 'Raw Data from mass spec', shape = folder, fillcolor = Linen]
step1 [label = 'Convert Sheet seperated data into single table for calculations']
step2 [label = 'Calculate Cal Curve (see Cal Curve Caluclation Diagram)']

# edge definitions with the node IDs
sourceData -> step10 -> step20 -> step21 
}")
```

<div class="grViz html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-74193f584023f326bdc2" style="width:672px;height:480px;"></div>
<script type="application/json" data-for="htmlwidget-74193f584023f326bdc2">{"x":{"diagram":"digraph {\n\ngraph [layout = dot]\n\n# define the global styles of the nodes. We can override these in box if we wish\nnode [shape = rectangle, style = filled, fillcolor = white]\n\nsourceData [label = \"Raw Data from mass spec\", shape = folder, fillcolor = Linen]\nstep1 [label = \"Convert Sheet seperated data into single table for calculations\"]\nstep2 [label = \"Calculate Cal Curve (see Cal Curve Caluclation Diagram)\"]\n\n# edge definitions with the node IDs\nsourceData -> step10 -> step20 -> step21 \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script>
