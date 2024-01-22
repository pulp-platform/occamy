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
    % for j in range(9*i+1, 9*(i+1)):
    {
        "thread": "${f'hart_{j}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr and args"},
            {"idx": 3, "label": "barrier"},
            {"idx": 4, "label": "compute"},
            {"idx": 5, "label": "barrier"},
            // Iteration 2
            {"idx": 8, "label": "clr interrupt"},
            {"idx": 9, "label": "get job ptr and args"},
            {"idx": 10, "label": "barrier"},
            {"idx": 11, "label": "compute"},
            {"idx": 12, "label": "barrier"},
        ]
    },
    % endfor
    {
        "thread": "${f'hart_{9*(i+1)}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr"},
            {"idx": 3, "label": "get job args"},
            {"idx": 4, "label": "get job operands"},
            {"idx": 5, "label": "barrier"},
            {"idx": 6, "label": "barrier"},
            {"idx": 7, "label": "copy output"},
            {"idx": 8, "label": "send interrupt"},
            // Iteration 2
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "get job ptr"},
            {"idx": 12, "label": "get job args"},
            {"idx": 13, "label": "get job operands"},
            {"idx": 14, "label": "barrier"},
            {"idx": 15, "label": "barrier"},
            {"idx": 16, "label": "copy output"},
            {"idx": 17, "label": "send interrupt"}
        ]
    },
% endfor
]