# Assembly Mips

Project for WUT

It is a minimal filter, that processes data by blocks. If every possible pixel in block
is examined, new data is read. If write buffer is full, data is saved to the output picture
and buffer is filled from the beginning.

Removing padding has a few flaws, filter works only for pictures with width divided by 4
(otherwise, there may be black lines at the left and at the right). To be corrected soon.

