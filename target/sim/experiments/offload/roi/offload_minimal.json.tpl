[
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
% for i in range(0, nr_clusters):
    // Compute cores
    % for j in range(0, 8):
    {
        "thread": "${f'hart_{1 + 9*i + j}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job"},
            // Iteration 2
            {"idx": 4, "label": "clr interrupt"},
            {"idx": 5, "label": "job"},
        ]
    },
    % endfor
    // DMA cores
    {
        "thread": "${f'hart_{1 + 9*i + 8}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr and args"},
            {"idx": 3, "label": "job"},
            // Iteration 2
            {"idx": 5, "label": "clr interrupt"},
            {"idx": 6, "label": "get job ptr and args"},
            {"idx": 7, "label": "job"},
        ]
    },
% endfor
]