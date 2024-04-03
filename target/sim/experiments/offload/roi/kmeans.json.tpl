[
    {
        "thread": "hart_0",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "prepare data"},
            {"idx": 2, "label": "send interrupt"},
            {"idx": 4, "label": "clr interrupt"},
            {"idx": 5, "label": "reduction"},
            {"idx": 6, "label": "normalize"},
            // Iteration 2
            {"idx": 7, "label": "prepare data"},
            {"idx": 8, "label": "send interrupt"},
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "reduction"},
            {"idx": 12, "label": "normalize"}
        ]
    },
% for i in range(0, nr_clusters):
    {
        "thread": "${f'hart_{1 + 9*i}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr and args"},
            {"idx": 3, "label": "init"},
            {"idx": 4, "label": "barrier"},
            {"idx": 5, "label": "setup"},
            {"idx": 6, "label": "assignment"},
            {"idx": 7, "label": "barrier"},
            {"idx": 8, "label": "update"},
            {"idx": 9, "label": "barrier"},
            {"idx": 10, "label": "reduction"},
            {"idx": 11, "label": "barrier"},
            // Iteration 2
            {"idx": 13, "label": "clr interrupt"},
            {"idx": 14, "label": "get job ptr and args"},
            {"idx": 15, "label": "barrier"},
            {"idx": 16, "label": "setup"},
            {"idx": 17, "label": "assignment"},
            {"idx": 18, "label": "barrier"},
            {"idx": 19, "label": "update"},
            {"idx": 20, "label": "barrier"},
            {"idx": 21, "label": "reduction"},
            {"idx": 22, "label": "barrier"},
        ]
    },
    % for j in range(1, 8):
    {
        "thread": "${f'hart_{1 + 9*i + j}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "get job ptr and args"},
            {"idx": 3, "label": "init"},
            {"idx": 4, "label": "barrier"},
            {"idx": 5, "label": "setup"},
            {"idx": 6, "label": "assignment"},
            {"idx": 7, "label": "barrier"},
            {"idx": 8, "label": "update"},
            {"idx": 9, "label": "barrier"},
            {"idx": 10, "label": "barrier"},
            // Iteration 2
            {"idx": 12, "label": "clr interrupt"},
            {"idx": 13, "label": "get job ptr and args"},
            {"idx": 14, "label": "barrier"},
            {"idx": 15, "label": "setup"},
            {"idx": 16, "label": "assignment"},
            {"idx": 17, "label": "barrier"},
            {"idx": 18, "label": "update"},
            {"idx": 19, "label": "barrier"},
            {"idx": 20, "label": "barrier"},
        ]
    },
    % endfor
    {
        "thread": "${f'dma_{1 + 9*i + 8}'}",
        "roi": [
            // Iteration 1
            {"idx": -3, "label": "samples"},
            {"idx": -2, "label": "centroids in"},
            // Iteration 2
            {"idx": -1, "label": "centroids in"},
        ]
    },
% endfor
]