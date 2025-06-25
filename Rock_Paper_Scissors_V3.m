function Rock_Paper_Scissors_V2()
    pkg load image
    clearvars -except ans; close all; clc;

    % Parameters
    worldsize = [30, 50];
    tile_size = 20;
    n_states = 3;
    current_step = 0;
    speed = 0.1;
    slider_min = 0.01;
    slider_max = 0.5;
    is_running = false;

    % Afbeeldingen inladen en resizen naar 20x20 px
    rock_img     = imresize(im2double(imread("rock.png")),     [tile_size tile_size]);
    paper_img    = imresize(im2double(imread("paper.png")),    [tile_size tile_size]);
    scissors_img = imresize(im2double(imread("scissors.png")), [tile_size tile_size]);
    img_list = {rock_img, paper_img, scissors_img};

    % Init world
    world = randi([0 2], worldsize);

    % GUI window
    f = figure('Name', 'RPS Automaton', 'Position', [100 100 1200 750], 'Color', [0.2,0.2,0.2]);
    movegui(f, 'center');

    % Axes for field
    ax = axes('Units', 'normalized', 'Position', [0.05 0.18 0.7 0.77], 'Color', [0.1 0.1 0.1]);
    img_handle = image(ax, zeros(worldsize(1)*tile_size, worldsize(2)*tile_size, 3));
    axis(ax, 'image', 'off');

    % Generation label
    lbl = uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.25 0.05 0.25 0.08], ...
        'String', 'Generation 0', 'FontWeight', 'bold', 'FontSize', 22, ...
        'ForegroundColor', [1 1 0.8], 'BackgroundColor', [1 0.4 0.7]);

    % --- BUTTONS ---
    btn_w = 0.15; btn_h = 0.08; btn_x = 0.8; spacing = 0.01;
    btn_colors = {[0.2 0.8 0.2],[1 0.4 0.7],[1 0.4 0.7],[0.6 0.6 1],[0.8 0.6 0.2],[0.2 0.2 0.2]};
    y0 = 0.80; % first button top

    uicontrol('Style','pushbutton','String','Step','Units','normalized','Position',[btn_x y0 btn_w btn_h],...
        'BackgroundColor',btn_colors{1},'FontSize',16,'Callback',@cb_step);

    uicontrol('Style','pushbutton','String','Start','Units','normalized','Position',[btn_x y0-btn_h-spacing btn_w btn_h],...
        'BackgroundColor',btn_colors{1},'FontSize',16,'Callback',@cb_start);

    uicontrol('Style','pushbutton','String','Stop','Units','normalized','Position',[btn_x y0-2*(btn_h+spacing) btn_w btn_h],...
        'BackgroundColor',btn_colors{2},'FontSize',16,'Callback',@cb_stop);

    uicontrol('Style','pushbutton','String','Reset','Units','normalized','Position',[btn_x y0-3*(btn_h+spacing) btn_w btn_h],...
        'BackgroundColor',btn_colors{3},'FontSize',16,'Callback',@cb_reset);

    uicontrol('Style','pushbutton','String','Import','Units','normalized','Position',[btn_x y0-4*(btn_h+spacing) btn_w btn_h],...
        'BackgroundColor',btn_colors{4},'FontSize',16,'Callback',@cb_import);

    uicontrol('Style','pushbutton','String','Export','Units','normalized','Position',[btn_x y0-5*(btn_h+spacing) btn_w btn_h],...
        'BackgroundColor',btn_colors{5},'FontSize',16,'Callback',@cb_export);

    uicontrol('Style','pushbutton','String','Quit','Units','normalized','Position',[btn_x y0-6*(btn_h+spacing) btn_w btn_h],...
        'BackgroundColor',btn_colors{6},'FontSize',16,'Callback',@(src,ev) close(f));

    % Speed slider
    uicontrol('Style','text','String','Speed (fast \u2192 slow):','Units','normalized','Position',[btn_x, y0-7*(btn_h+spacing), btn_w, 0.03], ...
        'ForegroundColor',[1 1 1],'BackgroundColor',[0.2,0.2,0.2],'FontWeight','bold');
    slider = uicontrol('Style','slider','Min',slider_min,'Max',slider_max,'Value',speed,...
        'Units','normalized','Position',[btn_x y0-7.5*(btn_h+spacing) btn_w 0.025],...
        'Callback',@cb_slider);

    % ---- Helper function to update display ----
    update_display();

    uiwait(f);

    % ------------------- Nested Functions -------------------

    function update_display()
        RGB = zeros(worldsize(1)*tile_size, worldsize(2)*tile_size, 3);
        for i = 1:worldsize(1)
            for j = 1:worldsize(2)
                x = (i-1)*tile_size+1;
                y = (j-1)*tile_size+1;
                val = world(i,j)+1; % 1-based for cell array
                RGB(x:x+tile_size-1, y:y+tile_size-1, :) = img_list{val};
            end
        end
        set(img_handle, 'CData', RGB);
        set(lbl, 'String', sprintf('Generation %d', current_step));
        drawnow;
    end

    function do_step()
        [rows, cols] = size(world);
        neighbors = cat(3, ...
            circshift(world, [-1,  0]), circshift(world, [-1,  1]), circshift(world, [ 0,  1]), ...
            circshift(world, [ 1,  1]), circshift(world, [ 1,  0]), circshift(world, [ 1, -1]), ...
            circshift(world, [ 0, -1]), circshift(world, [-1, -1]));
        rand_index = randi(8, rows, cols);
        selected = zeros(rows, cols);
        for k = 1:8
            mask = (rand_index == k);
            selected(mask) = neighbors(:,:,k)(mask);
        end
        wins = mod(selected - world, 3) == 1;
        world(wins) = selected(wins);
        current_step = current_step + 1;
        update_display();
    end

    function cb_step(~,~), do_step(); end

    function cb_start(~,~)
        is_running = true;
        while is_running && ishandle(f)
            do_step();
            pause(speed);
            drawnow;
        end
    end

    function cb_stop(~,~), is_running = false; end

    function cb_reset(~,~)
        world = randi([0 2], worldsize);
        current_step = 0;
        update_display();
    end

    function cb_import(~,~)
        [file, path] = uigetfile({'*.csv;*.txt','World files (*.csv,*.txt)'},'Import world');
        if isequal(file,0), return; end
        mat = csvread(fullfile(path,file));
        if ~isequal(size(mat), worldsize)
            errordlg('Wrong size for imported world.','Error');
            return;
        end
        world = mat;
        current_step = 0;
        update_display();
    end

    function cb_export(~,~)
        [file, path] = uiputfile({'*.csv;*.txt','World files (*.csv,*.txt)'},'Export world as');
        if isequal(file,0), return; end
        csvwrite(fullfile(path,file), world);
    end

    function cb_slider(src,~)
        speed = get(src,'Value');
    end
end

