module lsdalton_response_type_mod

  !> Which response calculations should be carried out?
  type rsp_tasksitem
     !> Response 
     logical :: doResponse
     !> Gradient
     logical :: doGrad
     !> Numerical Hessian
     logical :: doNumHess
     !> Numerical Gradient
     logical :: doNumGrad
     !> Numerical Gradient and Hessian
     logical :: doNumGradHess
     !> MCD
     logical :: doMCD
     !> NMR shield
     logical :: doNMRshield
     !> linear response
     logical :: dolinrsp
     !> Polarizability
     logical :: doAlpha
     !> 1st hyperpolarizability
     logical :: doBeta
     !> 2nd hyperpolarizability
     logical :: doGamma
     !> One-photon absorption (excitation energies + transition moments)
     logical :: doOPA
     !> Standard two-photon absorption
     logical :: doTPA
     !> Damped two-photon absorption
     logical :: doDTPA
     !> Excited state gradient
     logical :: doESG
     !> Excited state dipole moment
     logical :: doESD
  end type rsp_tasksitem

contains

  !> Set default logicals for various response properties (all false).
  subroutine rsp_tasks_set_default_config(tasksitem)
    implicit none
    type(rsp_tasksitem),intent(inout) :: tasksitem

    tasksitem%doResponse = .false.
    tasksitem%doGrad = .false.
    tasksitem%doNumHess = .false.
    tasksitem%doNumGrad = .false.
    tasksitem%doNumGradHess = .false.
    tasksitem%doMCD = .false.
    tasksitem%doNMRshield = .false.
    tasksitem%dolinrsp = .false.
    tasksitem%doAlpha = .false.
    tasksitem%doBeta = .false.
    tasksitem%doGamma = .false.
    tasksitem%doOPA = .false.
    tasksitem%doTPA = .false.
    tasksitem%doDTPA = .false.
    tasksitem%doESG = .false.
    tasksitem%doESD = .false.

  end subroutine rsp_tasks_set_default_config

end module lsdalton_response_type_mod