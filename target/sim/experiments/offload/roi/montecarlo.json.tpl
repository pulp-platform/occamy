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
    % if i == 0:
    {
        "thread": "${f'hart_1'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "compute psum"},
            {"idx": 4, "label": "barrier"},
            {"idx": 5, "label": "intra-cluster reduction"},
            {"idx": 6, "label": "barrier"},
            {"idx": 7, "label": "inter-cluster reduction"},
            // Iteration 2
            {"idx": 10, "label": "clr interrupt"},
            {"idx": 11, "label": "job setup"},
            {"idx": 12, "label": "compute psum"},
            {"idx": 13, "label": "barrier"},
            {"idx": 14, "label": "intra-cluster reduction"},
            {"idx": 15, "label": "barrier"},
            {"idx": 16, "label": "inter-cluster reduction"},
        ]
    },
    % else:
    {
        "thread": "${f'hart_{1 + 9*i}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "compute psum"},
            {"idx": 4, "label": "barrier"},
            {"idx": 5, "label": "intra-cluster reduction"},
            {"idx": 6, "label": "send psum"},
            // Iteration 2
            {"idx": 9, "label": "clr interrupt"},
            {"idx": 10, "label": "job setup"},
            {"idx": 11, "label": "compute psum"},
            {"idx": 12, "label": "barrier"},
            {"idx": 13, "label": "intra-cluster reduction"},
            {"idx": 14, "label": "send psum"},
        ]
    },
    % endif
    % for j in range(1, 8):
    {
        "thread": "${f'hart_{1 + 9*i + j}'}",
        "roi": [
            // Iteration 1
            {"idx": 1, "label": "clr interrupt"},
            {"idx": 2, "label": "job setup"},
            {"idx": 3, "label": "compute psum"},
            {"idx": 4, "label": "barrier"},
            // Iteration 2
            {"idx": 7, "label": "clr interrupt"},
            {"idx": 8, "label": "job setup"},
            {"idx": 9, "label": "compute psum"},
            {"idx": 10, "label": "barrier"},
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
            {"idx": 7, "label": "return"},
            // Iteration 2
            {"idx": 9, "label": "clr interrupt"},
            {"idx": 10, "label": "get job ptr"},
            {"idx": 11, "label": "get job args"},
            {"idx": 15, "label": "return"},
        ]
    },
% endfor
]