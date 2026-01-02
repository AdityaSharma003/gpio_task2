# Verilog Coding rules

### 1. The "Always" Rule

* **Rule:** If a signal is on the **left** side of an assignment inside an `always` block, it **MUST** be a `reg`.
* **Reason:** The `always` block implies "procedure" or "memory," so the variable must hold its value until the next update.

### 2. The "Assign" Rule

* **Rule:** If a signal is on the **left** side of an `assign` statement, it **MUST** be a `wire`.
* **Reason:** `assign` creates a permanent physical connection (like soldering a wire), not a storage memory.

### 3. The "Child-to-Parent" Rule

* **Rule:** When connecting a submodule's **output** to the parent module, the parent's receiving signal **MUST** be a `wire`.
* **Reason:** The submodule is already "driving" the signal. You cannot plug a hard driver directly into a storage bucket (`reg`).

### 4. The "Wire-then-Reg" Rule (The Fix)

* **Rule:** To store a submodule's output into a `reg`, you must first catch it with a `wire` in the parent's module, then copy it to the `reg` inside an `always` block.
* **Reason:** A `reg` can only have **one master** (the `always` block). If you connected the submodule directly to the `reg`, the submodule would try to fight the `always` block for control, causing a conflict as there is a difference in **who is doing the driving (writing)** versus **who is being read**.

### 5. The "Parent-to-Child" Rule

* **Rule:** When sending a signal **into** a submodule's input, the source can be a `reg` OR a `wire`.
* **Reason:** The submodule just listens to the voltage level; it doesn't care if that voltage comes from a register or a wire.

### 6. The "Input Port" Rule

* **Rule:** Inside a module definition, an `input` port is **ALWAYS** a `wire`.
* **Reason:** You cannot write to your own input; you only read from it.

### 7. The "Output Port" Rule

* **Rule:** Inside a module definition, an `output` port can be defined as `wire` (default) OR `reg`.
* **Reason:** Use `wire` if the value comes from combinational logic (`assign`). Use `reg` if the value is calculated in an `always` block.


# Getting Started with RISC-V on GitHub Codespaces

Follow the steps below to set up and run programs in your own Codespace.

---

## Step 1. Open the Repository

Go to:  
[https://github.com/vsdip/vsd-riscv2](https://github.com/vsdip/vsd-riscv2)

---

## Step 2. Create a Codespace

1. Log in with your GitHub account.
2. Click the green **Code** button.
3. Select **Open with Codespaces** → **New codespace**.
4. Wait while the environment builds. (First time may take 10–15 minutes.)

---

## Step 3. Verify the Setup

In the terminal that opens, type:

```bash
riscv64-unknown-elf-gcc --version
spike --version
iverilog -V
````

You should see version information for each tool.

---

## Step 4. Run Your First Program

1. Go to the `samples` folder.
2. Compile the program:

   ```bash
   riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
   ```
3. Run it with Spike:

   ```bash
   spike pk sum1ton.o
   ```

Expected output:

```text
Sum from 1 to 9 is 45
```

---

## Step 5. Next Steps

* You can edit and run your own C programs.
* You can also try Verilog programs using `iverilog`.

---

# Working with GUI Desktop (noVNC) – Advanced

The following steps show how to use a full Linux desktop inside your Codespace and run the same RISC-V programs there.

---

## Step 6. Launch the noVNC Desktop

1. In your Codespace, click the **PORTS** tab.

2. Look for the forwarded port named **noVNC Desktop (6080)**.

3. Click the **Forwarded Address** link.

   ![noVNC port](images/2.png)

4. A new browser tab opens with a directory listing. Click **`vnc_lite.html`**.

   ![noVNC directory listing](images/3.png)

5. The Linux desktop appears in your browser.

   ![Desktop view](images/4.png)

---

## Step 7. Open a Terminal Inside the Desktop

1. Right-click anywhere on the desktop background.
2. Select **Open Terminal Here**.

   ![Open terminal here](images/4.png)

A terminal window will open on the desktop.

---

## Step 8. Navigate to the Sample Programs

In the terminal, go to the workspace and then to the `samples` folder:

```bash
cd /workspaces/vsd-riscv2
cd samples
ls -ltr
```

You should see files like `sum1ton.c`, `1ton_custom.c`, `load.S`, and `Makefile`.

![Samples folder listing](images/5.png)

---

## Step 9. Compile and Run Using Native GCC (x86)

First, compile and run the C program with the standard `gcc` compiler:

```bash
gcc sum1ton.c
./a.out
```

Expected output:

```text
Sum from 1 to 9 is 45
```

![Native GCC run](images/6.png)

---

## Step 10. Compile and Run Using RISC-V GCC and Spike

Now compile the same program for RISC-V and run it on the Spike ISA simulator:

```bash
riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
spike pk sum1ton.o
```

You will see the proxy kernel (`pk`) messages and then the program output.

![Spike run](images/7.png)

---

## Step 11. Edit the C Program Using gedit (GUI Editor)

To edit the program using a graphical editor:

```bash
gedit sum1ton.c &
```

This opens `sum1ton.c` in **gedit** on the noVNC desktop.

![gedit editing](images/8.png)

Make changes (for example, change `n = 9;` to another value), save the file, and re-run:

```bash
riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
spike pk sum1ton.o
```

---

You have now:

* Launched a full Linux desktop inside GitHub Codespaces
* Compiled and executed a C program with native GCC
* Compiled and executed the same program on a RISC-V target using Spike
* Edited and rebuilt the code using a GUI editor over noVNC

You’re ready to explore more RISC-V and Verilog labs in this Codespace.


