merlin32 -v . pass_func_data.s
copy          pass_func_data    pass.func.data
prodosfs call_convention.po rm /pass.func.data
prodosfs call_convention.po cp  pass.func.data /
prodosfs call_convention.po cat
