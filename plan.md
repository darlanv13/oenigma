The user wants to add an option to edit and delete enigmas, replacing the current "Manage" (Gerenciar) button.
The user also reported that enigmas are not showing up in the app still, and there are intermittent LateInitializationErrors.

Wait, the LateInitializationError was just fixed in my last commit. I will inform the user it was fixed.
For editing and deleting enigmas: I will create `_deleteEnigma` and `_showEditEnigmaModal`. `_showManageEnigmaModal` manages tools/URL hints inside of it, so I will either merge this functionality into `_showEditEnigmaModal` or keep `_showEditEnigmaModal` dedicated. Actually, replacing "Gerenciar" with "Editar" which opens `_showManageEnigmaModal` with editing basic fields too might be better.

I will use `request_user_input` to clarify with the user.
