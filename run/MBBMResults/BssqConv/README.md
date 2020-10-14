# Boussinesq Convergence

- This directory contains the computational runs associated with the
  convergence of the boussinesq parameter.

- PSet1: refers to the boussinesq convergence test corresponding to 
  the first set of parameter choices described in the Janurary 28th
  2020 meeting notes.

- PSet1CorVel: referes to the corrected velocitiy initialization for 
  PSet 1. It turns out that there was an issue with the w 
  initialization being on the wrong x mesh. I have also now evaluated
  the rl function on u and w meshes for correct initialization near 
  the interface

- PSet1FM: refered to a finer spatial and temporal mesh run of PSet1.
  This set of runs also contains the corrected velocity initialization
  of PSet1CorVel. These are successive improvements.

- PSet1SmWv: Reducing the wave perturbation magnitude for PSet1. Idea
  here is to reduce the asymptotic continunity error. This set of runs
  also contains the corrected velocity initialization of
  PSet1CorVel. These are successive improvements.
