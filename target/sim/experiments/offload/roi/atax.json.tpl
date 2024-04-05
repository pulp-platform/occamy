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
            {"idx": 4, "label": "Ax"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "AtAx"},
            {"idx": 7, "label": "barrier"},
            // Iteration 2
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "job setup"},
            {"idx": 12, "label": "barrier"},
            {"idx": 13, "label": "Ax"},
            {"idx": 14, "label": "barrier"},
            {"idx": 15, "label": "AtAx"},
            {"idx": 16, "label": "barrier"},
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
            {"idx": 16, "label": "return"},
        ]
    },

    // DMA engine proper
    % if i == 0 or multicast:
    {
        "thread": "${f'dma_{1 + 9*i + 8}'}",
        "roi": [
            // Iteration 1
            {"idx": -10, "label": "A in"},
            {"idx": -9, "label": "x in"},
            {"idx": -8, "label": "y tile in"},
            {"idx": -7, "label": "tmp in"},
            {"idx": -6, "label": "y out"},
            // Iteration 2
            {"idx": -5, "label": "A in"},
            {"idx": -4, "label": "x in"},
            {"idx": -3, "label": "y tile in"},
            {"idx": -2, "label": "tmp in"},
            {"idx": -1, "label": "y out"},
        ]
    },
    % else:
    {
        "thread": "${f'dma_{1 + 9*i + 8}'}",
        "roi": [
            // Iteration 1
            {"idx": -12, "label": "job info"},
            {"idx": -11, "label": "A in"},
            {"idx": -10, "label": "x in"},
            {"idx": -9, "label": "y tile in"},
            {"idx": -8, "label": "tmp in"},
            {"idx": -7, "label": "y out"},
            // Iteration 2
            {"idx": -6, "label": "job info"},
            {"idx": -5, "label": "A in"},
            {"idx": -4, "label": "x in"},
            {"idx": -3, "label": "y tile in"},
            {"idx": -2, "label": "tmp in"},
            {"idx": -1, "label": "y out"},
        ]
    },
    % endif
% endfor
]