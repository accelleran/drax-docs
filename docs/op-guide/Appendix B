## Appendix: License Error Codes

Sometimes you might run into issues when trying to launch dRAX due to a licensing error. A list of possible error codes is provided below:

|ID        | Tag                   | Explanation                                                                       |
|----------|-----------------------| ----------------------------------------------------------------------------------|
| E001      | ENotInEnv             | Environment variable not set                                                      |
| E002      | EInvalidUTF8          | The content of the environment varable is not valid UTF8                          |
| E003      | ECannotOpen          |  Cannot open license file, was it added as a secret with the right name? To verify whether it's loaded correctly, run: ```  bash kubectl get secret accelleran-license -o'jsonpath={.data.license\\.crt}' ```   which should give you a base64 encoded dump. |
|E004|ELicenseExpired|Your license is expired! You'll likely need a new license from Accelleran|
|E005|EDecryption|An error occurred during decryption
|E006|EVerification|An error occurred during verification
|E007|EMissingPermission|You do not have the permissions to execute the software. You'll likely need a more permissive license from Accelleran.
|E008|ESOError|Inner function returned an error
|E009|ERunFn|Cannot find the correct function in the library
|E010|ELoadLibrary|Cannot load the .so file
|E011|ETryWait|An error occurred while waiting for the subprocess to return
|E012|ESpawn|Could not spawn subprocess
|E013|EWriteDecrypted|Cannot write to file descriptor
|E014|EMemFd|Cannot open memory file descriptor
|E015|ECypher|Cannot create cypher|
