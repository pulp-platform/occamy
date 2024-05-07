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
            {"idx": 4, "label": "compute"},
            {"idx": 5, "label": "barrier"},
            // Iteration 2
            {"idx": 8, "label": "clr interrupt"},
            {"idx": 9, "label": "job setup"},
            {"idx": 10, "label": "barrier"},
            {"idx": 11, "label": "compute"},
            {"idx": 12, "label": "barrier"},
        ]
    },
    % endfor

    // DMA cores
    {
        "thread": "${f'hart_{1 + 9*i + 8}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "copy data in"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "copy data out"},
            {"idx": 7, "label": "return"},
            // Iteration 2
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "get job ptr"},
            {"idx": 12, "label": "get job args"},
            {"idx": 13, "label": "copy data in"},
            {"idx": 14, "label": "barrier"},
            {"idx": 15, "label": "copy data out"},
            {"idx": 16, "label": "return"}
        ]
    },
% endfor
]