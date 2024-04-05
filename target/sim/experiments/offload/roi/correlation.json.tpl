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
        ## Only cluster 0 computes step 2
        % if i == 0:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "barrier"},
            {"idx": 4, "label": "compute step 1"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "compute step 2"},
            {"idx": 7, "label": "barrier"},
            // Iteration 2
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "job setup"},
            {"idx": 12, "label": "barrier"},
            {"idx": 13, "label": "compute step 1"},
            {"idx": 14, "label": "barrier"},
            {"idx": 15, "label": "compute step 2"},
            {"idx": 16, "label": "barrier"},
        % else:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "barrier"},
            {"idx": 4, "label": "compute step 1"},
            {"idx": 5, "label": "barrier"},
            // Iteration 2
            {"idx": 8, "label": "clr interrupt"},
            {"idx": 9, "label": "job setup"},
            {"idx": 10, "label": "barrier"},
            {"idx": 11, "label": "compute step 1"},
            {"idx": 12, "label": "barrier"},
        % endif
        ]
    },
    % endfor

    // DMA cores
    {
        "thread": "${f'hart_{1 + 9*i + 8}'}",
        "roi": [
    ## Cluster 0's DMA core aggregates the data from step 1
    % if i == 0:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "copy data in"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "copy step1 data"},
            {"idx": 7, "label": "barrier"},
            {"idx": 8, "label": "copy data out"},
            {"idx": 9, "label": "return"},
            // Iteration 2
            {"idx": 12, "label": "clr interrupt"},
            {"idx": 13, "label": "get job ptr"},
            {"idx": 14, "label": "get job args"},
            {"idx": 15, "label": "copy data in"},
            {"idx": 16, "label": "barrier"},
            {"idx": 17, "label": "copy step1 data"},
            {"idx": 18, "label": "barrier"},
            {"idx": 19, "label": "copy data out"},
            {"idx": 20, "label": "return"},
    % else:
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "copy data in"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "return"},
            // Iteration 2
            {"idx": 9, "label": "clr interrupt"},
            {"idx": 10, "label": "get job ptr"},
            {"idx": 11, "label": "get job args"},
            {"idx": 12, "label": "copy data in"},
            {"idx": 13, "label": "barrier"},
            {"idx": 14, "label": "return"},
    % endif
        ]
    },
% endfor
]