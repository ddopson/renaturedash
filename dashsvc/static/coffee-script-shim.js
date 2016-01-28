process = {}
process.stdout = {}
process.stdout.isTTY = function () { return false; }

process.env = {}
process.env.NODE_DISABLE_COLORS = true
