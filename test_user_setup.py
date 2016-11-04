# -*- coding: utf-8 -*-
""""""

import unittest
import sys
import subprocess
import docker


class TestDocker(unittest.TestCase):
    command = "docker run --rm --entrypoint /usr/local/bin/user-setup"

    image_tag = "visie/debian:latest"

    message = "Process failed. Expected '{}' got '{}'\n{}"

    def doTest(self, command, expected_result="\n"):
        args = self.command + " " + command + " " + self.image_tag
        process = subprocess.Popen(
            args=[arg for arg in args.split(" ") if len(arg)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        process.wait()
        stdout = process.stdout.read()
        message = self.message.format(
            expected_result.replace("\n", "\\n"),
            stdout.replace("\n", "\\n"),
            process.stderr.read()
        )
        self.assertEqual(expected_result, stdout, message)

    @classmethod
    def setUpClass(cls):
        client = docker.Client()
        build = client.build(path=".", tag=cls.image_tag, rm=True, decode=True)
        for step in build:
            sys.stdout.write(step.get("stream"))
        for image in client.images():
            if image.get("RepoTags") == [u"<none>:<none>"]:
                client.remove_image(image.get("Id"))

    def testRunWithNoArgs(self):
        """Sem argumentos, executa como root"""
        self.doTest("", "root 0 0 /root /bin/bash\n")

    def testRunWithExistingNumericUser(self):
        """Podemos optar por enviar o UID do usuário considerado 'atual'"""
        self.doTest("-u1", "daemon 1 1 /usr/sbin /usr/sbin/nologin\n")

    def testRunWithExistingNamedUser(self):
        """Também podemos enviar o nome de usuário para execução"""
        self.doTest("-udaemon", "daemon 1 1 /usr/sbin /usr/sbin/nologin\n")

    def testRunWithExistingNumericUserAndGroup(self):
        """
        Como não estamos roando como root, não será possível alterar o GID
        do usuário. Ver o teste RunWithExistingEnvironmentUserandNewGroup
        """
        self.doTest("-u1:2", "daemon 1 1 /usr/sbin /usr/sbin/nologin\n")

    def testRunWithNonExistingNumericUser(self):
        """
        Passando um UID, podemos executar até mesmo como um usuário que não
        existe...
        """
        self.doTest("-u1000", "docker 1000 1000 /tmp/docker /bin/bash\n")

    def testRunWithNonExistingNamedUser(self):
        """ ... o que não é o caso de tentar passar um nome de usuário
        que ainda não exista
        """
        self.doTest("-udocker", "")

    def testRunWithEnvironmentNumericUID(self):
        """
        Podemos nos utilizar de variáveis de ambiente para escolher informações
        do usuário que queremos para a execução, mas mantendo o usuário atual
        como root. As variáveis podem ser UID, que recebe um UID
        """
        self.doTest("-eUID=1", "daemon 1 1 /usr/sbin /usr/sbin/nologin\n")

    def testRunWithEnvironmentNamedUID(self):
        """Um UID, recebendo um nome de usuário"""
        self.doTest(
            "-eUID=daemon",
            "daemon 1 1 /usr/sbin /usr/sbin/nologin\n"
        )

    def testRunWithEnvironmentNamedUsername(self):
        """USERNAME, que recebe um nome de usuário"""
        self.doTest(
            "-eUSERNAME=daemon",
            "daemon 1 1 /usr/sbin /usr/sbin/nologin\n"
        )

    def testRunWithEnvironmentNamedUser(self):
        """Ou USER, que trabalha como USERNAME"""
        self.doTest(
            "-eUSER=daemon",
            "daemon 1 1 /usr/sbin /usr/sbin/nologin\n"
        )

    def testRunWithEnvironmentNonExistingNumericUID(self):
        """Podemos informar UID numérico"""
        self.doTest("-eUID=1000", "docker 1000 1000 /home/docker /bin/bash\n")

    def testRunWithEnvironmentNonExistingNamedUID(self):
        """
        Ou um nome para um novo usuário... Neste caso, conseguimos criar porque
        o usuário em execução ainda é o root
        """
        self.doTest(
            "-eUID=docker",
            "docker 1000 1000 /home/docker /bin/bash\n"
        )

    def testRunWithEnvironmentNamedUsernameAndChangingUID(self):
        """
        Quando somos root, podemos escolher o nome de usuário e seu UID
        """
        self.doTest(
            "-eUSERNAME=daemon -eUID=1001",
            "daemon 1001 1001 /usr/sbin /usr/sbin/nologin\n"
        )

    def testRunWithEnvironmentNamedUsernameAndChangingUID(self):
        """E até mesmo um nome de usuário, um UID e um GID"""
        self.doTest(
            "-eUSERNAME=newuser -eUID=1001 -eGID=1002",
            "newuser 1001 1002 /home/newuser /bin/bash\n"
        )

    def testRunWithEnvironmentNewHome(self):
        """E até mesmo um nome de usuário, um UID e um GID"""
        self.doTest(
            "-eHOME=/tmp/newhome",
            "root 0 0 /tmp/newhome /bin/bash\n"
        )


if __name__ == "__main__":
    unittest.main()
