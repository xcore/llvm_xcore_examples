===================
LLVM xCORE examples
===================

:Maintainer: https://github.com/rlsosborne
:Description: LLVM IR examples for the xCORE backend

Introduction
============

This repository contains various examples demonstrating how to use of the xCORE
specific intrinsics present in the LLVM xCORE backend.

Recommended reading
===================

* `Getting started with LLVM <http://llvm.org/docs/GettingStarted.html>`_
* `LLVM language reference manual <http://llvm.org/docs/LangRef.html>`_
* `Tools Development Guide <https://www.xmos.com/node/14310?version=latest>`_ (contains the xCORE ABI)
* `The XMOS XS1 Architecture <https://www.xmos.com/node/14080?version=latest>`_

Representation of resources
===========================

Resources identifers are represented as pointers to ``i8`` in address space 1.
The benefit of representing these as pointers is that we can use LLVM's alias
analysis infrastructure to determine whether two resource identifier can point
to the same resource. The attributes ``noalias`` and ``nocapture`` can be
applied to resource identifiers if appropriate.

Examples
========

* threads.ll - Example showing how to start threads
* chanends.ll - Example of how to use chanend resources
* timers.ll - Example of how to use timers
* ports.ll - Example showing how to use ports
* events.ll - Example of how to implement XC's select statement using events
* multiple_returns.ll - Example of how to call a multiple return function
