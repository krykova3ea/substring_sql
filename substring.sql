DECLARE
    v_str        strings_26.stroka%TYPE; -- используемая строка
    v_sub_str    strings_26.stroka%TYPE; -- используемая подстрока
    v_len        NUMBER; -- длина строки
    v_entry      NUMBER; -- количество вхождений подстроки в строку
    v_max_len    NUMBER; -- максимально длина подстроки
    v_2_start    NUMBER; -- начальная позиция 2 подстроки
    v_sub_index  NUMBER; -- индекс используемой подстроки
    v_rowoutput  VARCHAR2(4096); -- используемая выводимая строка
    v_line       VARCHAR2(4096); -- горизонтальная черта в таблице
  -- типы данных для хранения подстрок для каждой строки
    TYPE substring IS RECORD (
        value     strings_26.stroka%TYPE,
        startpos1 NUMBER,
        startpos2 NUMBER
    );
    -- массив подстрок
    TYPE substringstable IS
        TABLE OF substring;
    -- массив строк
    TYPE stringstable IS
        TABLE OF substringstable INDEX BY strings_26.stroka%TYPE;
        
  -- массив из строк к их подстрокам
    v_substrings stringstable; 
    
    -- исходные строки
    CURSOR c_row_cursor IS
    SELECT
        stroka
    FROM
        strings_26;
    
     -- типы данных для итогового вывода
    TYPE output_row IS
        TABLE OF VARCHAR2(4000);
    TYPE output_row_len IS
        TABLE OF NUMBER INDEX BY PLS_INTEGER;
    header       output_row := output_row('Строка', 'Подстрока', 'Номер позиции начала 1', 'Номер позиции начала 2');
    lengths      output_row_len;
    TYPE output_table IS
        TABLE OF output_row INDEX BY PLS_INTEGER;

  -- итоговая выводимая таблица (результат программы)
    v_result     output_table;
BEGIN
  -- проверяем строки
    FOR row IN c_row_cursor LOOP
        v_str := row.stroka;
        -- если строка пустая или имеет длину меньше двух
        IF v_str IS NULL OR length(v_str) < 2 THEN
            v_result(nvl(v_result.last + 1, 1)) := output_row(nvl(v_str, '(null)'), '-', '-', '-');

            CONTINUE;
        END IF;
        -- инициализируем массив
        v_substrings(v_str) := substringstable();
        v_max_len := NULL;
        v_len := length(v_str);
        FOR currentlength IN REVERSE 1..( floor(v_len / 2) ) LOOP
            EXIT WHEN currentlength < v_max_len;
            << lastloop >> FOR startpos IN 1..( v_len - currentlength + 1 ) LOOP
                v_sub_str := substr(v_str, startpos, currentlength);
                v_entry := ( v_len - length(replace(lower(v_str), lower(v_sub_str))) ) / length(v_sub_str);

                v_2_start := instr(v_str, v_sub_str, startpos + currentlength);
        -- если вхождений не ровно 2 раза или же второе вхождение до конца первого
                CONTINUE WHEN v_entry != 2 OR v_2_start = 0;
        -- проверяем, пересекаются и подстроки
                FOR i IN 1..nvl(v_substrings(v_str).last, 0) LOOP
                    CONTINUE lastloop WHEN startpos BETWEEN v_substrings(v_str)(i).startpos1 AND v_substrings(v_str)(i).startpos1 + currentlength - 1
                    OR startpos BETWEEN v_substrings(v_str)(i).startpos2 AND v_substrings(v_str)(i).startpos2 + currentlength - 1 OR v_2_start
                    BETWEEN v_substrings(v_str)(i).startpos1 AND v_substrings(v_str)(i).startpos1 + currentlength - 1 OR v_2_start BETWEEN
                    v_substrings(v_str)(i).startpos2 AND v_substrings(v_str)(i).startpos2 + currentlength - 1;
                END LOOP;
        -- индекс новой подстроки
                v_sub_index := nvl(v_substrings(v_str).last+1, 1);
        -- добавляем подстроку к списку
                v_substrings(v_str).extend;
                v_substrings(v_str)(v_sub_index).value := v_sub_str;
                v_substrings(v_str)(v_sub_index).startpos1 := startpos;
                v_substrings(v_str)(v_sub_index).startpos2 := v_2_start;
        -- добавляем строку в итоговую таблицу
                IF v_sub_index = 1 THEN
                    v_result(nvl(v_result.last + 1, 1)) := output_row(v_str, v_sub_str, startpos, v_2_start);
                ELSE
                    v_result(nvl(v_result.last + 1, 1)) := output_row(' ', v_sub_str, startpos, v_2_start);
                END IF;

                v_max_len := currentlength;
            END LOOP lastloop;

        END LOOP;
        -- если нет строк
        IF v_substrings(v_str).count = 0 THEN
            v_result(nvl(v_result.last + 1, 1)) := output_row(v_str, '-', '-', '-');
        END IF;

    END LOOP;

-- выводим результат
  -- вносим длины столбцов выводимой таблицы
    FOR i IN 1..header.last LOOP
        lengths(i) := length(header(i));
    END LOOP;
-- находим длины столбцов
    FOR row IN 1..v_result.last LOOP
        FOR col IN 1..v_result(row).last LOOP
            IF length(v_result(row)(col)) > lengths(col) THEN
                lengths(col) := length(v_result(row)(col));
            END IF;
        END LOOP;
    END LOOP;
-- выводим заголовок таблицы
    FOR i IN 1..( header.last - 1 ) LOOP
        v_rowoutput := v_rowoutput
                       || rpad(header(i), lengths(i), ' ')
                       || ' | ';
    END LOOP;

    v_rowoutput := v_rowoutput || header(header.last);
    dbms_output.put_line(v_rowoutput);
-- заполняем горизонтальную линию
    FOR i IN 1..( header.last - 1 ) LOOP
        v_line := v_line
                  || rpad('-', lengths(i), '-')
                  || '-|-';
    END LOOP;

    v_line := v_line
              || rpad('-', lengths(lengths.last), '-');
-- выводим таблицу result
    FOR row IN 1..v_result.last LOOP
        dbms_output.put_line(v_line);
        v_rowoutput := '';
        FOR col IN 1..( v_result(row).last - 1 ) LOOP
            v_rowoutput := v_rowoutput
                           || rpad(v_result(row)(col), lengths(col), ' ')
                           || ' | ';
        END LOOP;

        v_rowoutput := v_rowoutput
                       || v_result(row)(v_result(row).last);

        dbms_output.put_line(v_rowoutput);
    END LOOP;

END;
/
