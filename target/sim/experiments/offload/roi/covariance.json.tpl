<%
import math

num_levels = math.ceil(math.log2(nr_clusters))
%>
[
    // CVA6 core
    {
        "thread": "hart_0",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "prepare data"},
            {"idx": 2, "label": "send interrupt"},
            {"idx": 4, "label": "clr interrupt"},
            // Iteration 2
            {"idx": 5, "label": "prepare data"},
            {"idx": 6, "label": "send interrupt"},
            {"idx": 8, "label": "clr interrupt"}
        ]
    },

// Snitch clusters
% for i in range(0, nr_clusters):

    // Compute cores
    % for j in range(0, 8):
    {
        "thread": "${f'hart_{1 + 9*i + j}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "barrier"},
            {"idx": 4, "label": "compute mean"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "center data"},
            {"idx": 7, "label": "barrier"},
            {"idx": 8, "label": "AtA"},
            {"idx": 9, "label": "barrier"},
            <% offs = 0 %>
        % for k in range(num_levels):
            {"idx": ${10 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${11 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${10 + offs}, "label": "normalize"},
            {"idx": ${11 + offs}, "label": "barrier"},
            // Iteration 2
            {"idx": ${14 + offs}, "label": "clr interrupt"},
            {"idx": ${15 + offs}, "label": "job setup"},
            {"idx": ${16 + offs}, "label": "barrier"},
            {"idx": ${17 + offs}, "label": "compute mean"},
            {"idx": ${18 + offs}, "label": "barrier"},
            {"idx": ${19 + offs}, "label": "center data"},
            {"idx": ${20 + offs}, "label": "barrier"},
            {"idx": ${21 + offs}, "label": "AtA"},
            {"idx": ${22 + offs}, "label": "barrier"},
        % for k in range(num_levels):
            {"idx": ${23 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${24 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${23 + offs}, "label": "normalize"},
            {"idx": ${24 + offs}, "label": "barrier"},
        ]
    },
    % endfor

    // DMA cores
    {
        "thread": "${f'hart_{1 + 9*i + 8}'}",
        "roi": [
    ## Cluster 0's DMA copies the data out
    % if i == 0:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "copy data in"},
            {"idx": 5, "label": "barrier"},
            <% offs = 0 %>
        % for k in range(num_levels):
            {"idx": ${6 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${7 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${6 + offs}, "label": "copy data out"},
            {"idx": ${7 + offs}, "label": "return"},
            // Iteration 2
            {"idx": ${10 + offs}, "label": "clr interrupt"},
            {"idx": ${11 + offs}, "label": "get job ptr"},
            {"idx": ${12 + offs}, "label": "get job args"},
            {"idx": ${13 + offs}, "label": "copy data in"},
            {"idx": ${14 + offs}, "label": "barrier"},
        % for k in range(num_levels):
            {"idx": ${15 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${16 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${15 + offs}, "label": "copy data out"},
            {"idx": ${16 + offs}, "label": "return"},
    % else:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "copy data in"},
            {"idx": 5, "label": "barrier"},
            <% offs = 0 %>
        % for k in range(num_levels):
            {"idx": ${6 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${7 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${6 + offs}, "label": "return"},
            // Iteration 2
            {"idx": ${9 + offs}, "label": "clr interrupt"},
            {"idx": ${10 + offs}, "label": "get job ptr"},
            {"idx": ${11 + offs}, "label": "get job args"},
            {"idx": ${12 + offs}, "label": "copy data in"},
            {"idx": ${13 + offs}, "label": "barrier"},
        % for k in range(num_levels):
            {"idx": ${14 + offs}, "label": "${f"reduction {k}"}"},
            {"idx": ${15 + offs}, "label": "barrier"},
            <% offs += 2%>
        % endfor
            {"idx": ${14 + offs}, "label": "return"},
    % endif
        ]
    },
% endfor
]